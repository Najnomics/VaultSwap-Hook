// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {euint128, euint8, euint32, euint64, ebool, FHE} from "@fhenixprotocol/cofhe-contracts/FHE.sol";

/**
 * @title IntelligentRouter
 * @notice Cross-pool routing optimization engine for VaultSwap
 * @dev Provides intelligent routing across multiple Uniswap V4 pools for optimal execution
 */
library IntelligentRouter {
    
    // =============================================================
    //                    CONSTANTS
    // =============================================================

    /// @notice Routing strategies
    uint8 public constant SINGLE_POOL = 0;
    uint8 public constant MULTI_POOL_SPLIT = 1;
    uint8 public constant DYNAMIC_ROUTING = 2;
    uint8 public constant LIQUIDITY_OPTIMIZED = 3;

    /// @notice Maximum pools for routing
    uint256 public constant MAX_POOLS = 5;
    
    /// @notice Basis points for percentage calculations
    uint256 public constant BASIS_POINTS = 10000;

    // =============================================================
    //                    STRUCTS
    // =============================================================

    struct PoolAnalysis {
        PoolKey poolKey;
        euint128 availableLiquidity;
        euint128 estimatedPriceImpact;
        euint64 gasEstimate;
        euint32 executionPriority;
        euint128 optimalAllocation;
        uint24 fee;
        bool isActive;
    }

    struct RoutingPlan {
        uint256 poolCount;
        PoolKey[] pools;
        uint256[] allocations; // In basis points (10000 = 100%)
        euint128 estimatedGasTotal;
        euint128 estimatedImpactTotal;
        euint32 confidenceScore;
    }

    struct MarketMetrics {
        euint128 totalLiquidity;
        euint128 averageGasPrice;
        euint128 volatilityIndex;
        euint64 lastUpdate;
    }

    // =============================================================
    //                    EVENTS
    // =============================================================

    event RoutingPlanCreated(bytes32 indexed orderId, uint256 poolCount, uint256 totalAllocation);
    event PoolAnalyzed(PoolKey indexed pool, uint256 liquidity, uint256 impact);
    event RouteOptimized(bytes32 indexed orderId, uint8 strategy, uint256 improvement);

    // =============================================================
    //                    ROUTING FUNCTIONS
    // =============================================================

    /**
     * @notice Discover all available pools for a token pair
     * @param basePool Base pool key to derive token pair from
     * @return availablePools Array of discovered pools
     */
    function discoverAvailablePools(PoolKey memory basePool) internal pure returns (PoolKey[] memory availablePools) {
        // Simplified pool discovery - in production would query pool registry
        availablePools = new PoolKey[](3);
        
        // Create pools with different fee tiers for the same token pair
        availablePools[0] = PoolKey({
            currency0: basePool.currency0,
            currency1: basePool.currency1,
            fee: 500,   // 0.05%
            tickSpacing: 10,
            hooks: IHooks(address(0))
        });
        
        availablePools[1] = PoolKey({
            currency0: basePool.currency0,
            currency1: basePool.currency1,
            fee: 3000,  // 0.3%
            tickSpacing: 60,
            hooks: IHooks(address(0))
        });
        
        availablePools[2] = PoolKey({
            currency0: basePool.currency0,
            currency1: basePool.currency1,
            fee: 10000, // 1%
            tickSpacing: 200,
            hooks: IHooks(address(0))
        });
        
        return availablePools;
    }

    /**
     * @notice Analyze a pool for routing optimization
     * @param pool Pool to analyze
     * @param orderAmount Order amount for impact calculation
     * @return analysis Complete pool analysis
     */
    function analyzePool(PoolKey memory pool, euint128 orderAmount) internal returns (PoolAnalysis memory analysis) {
        // Simplified pool analysis - in production would query actual pool state
        analysis = PoolAnalysis({
            poolKey: pool,
            availableLiquidity: _estimateLiquidity(pool),
            estimatedPriceImpact: _estimatePriceImpact(pool, orderAmount),
            gasEstimate: _estimateGasCost(pool),
            executionPriority: _calculatePriority(pool),
            optimalAllocation: FHE.asEuint128(0), // Calculated later
            fee: pool.fee,
            isActive: true
        });
        
        return analysis;
    }

    /**
     * @notice Calculate optimal allocation across multiple pools
     * @param pools Array of pool analyses
     * @param orderAmount Total order amount
     * @param strategy Routing strategy
     * @return allocations Optimal allocation percentages
     */
    function calculateOptimalAllocation(
        PoolKey[] memory pools,
        euint128 orderAmount,
        euint8 strategy
    ) internal returns (uint256[] memory allocations) {
        allocations = new uint256[](pools.length);
        
        uint8 strategyType = uint8(euint8.unwrap(strategy));
        
        if (strategyType == SINGLE_POOL) {
            return _calculateSinglePoolAllocation(pools, orderAmount);
        } else if (strategyType == MULTI_POOL_SPLIT) {
            return _calculateMultiPoolAllocation(pools, orderAmount);
        } else if (strategyType == DYNAMIC_ROUTING) {
            return _calculateDynamicAllocation(pools, orderAmount);
        } else if (strategyType == LIQUIDITY_OPTIMIZED) {
            return _calculateLiquidityOptimizedAllocation(pools, orderAmount);
        }
        
        // Default to single pool
        return _calculateSinglePoolAllocation(pools, orderAmount);
    }

    /**
     * @notice Create comprehensive routing plan
     * @param pools Available pools
     * @param orderAmount Order amount
     * @param strategy Routing strategy
     * @return plan Complete routing plan
     */
    function createRoutingPlan(
        PoolKey[] memory pools,
        euint128 orderAmount,
        euint8 strategy
    ) internal returns (RoutingPlan memory plan) {
        // Calculate optimal allocations
        uint256[] memory allocations = calculateOptimalAllocation(pools, orderAmount, strategy);
        
        // Filter active pools (non-zero allocations)
        (PoolKey[] memory activePools, uint256[] memory activeAllocations) = _filterActivePools(pools, allocations);
        
        plan = RoutingPlan({
            poolCount: activePools.length,
            pools: activePools,
            allocations: activeAllocations,
            estimatedGasTotal: _calculateTotalGas(activePools),
            estimatedImpactTotal: _calculateTotalImpact(activePools, orderAmount, activeAllocations),
            confidenceScore: _calculateConfidenceScore(activePools, activeAllocations)
        });
        
        return plan;
    }

    /**
     * @notice Optimize routing based on real-time conditions
     * @param currentPlan Current routing plan
     * @param marketMetrics Current market conditions
     * @return optimizedPlan Improved routing plan
     */
    function optimizeRouting(
        RoutingPlan memory currentPlan,
        MarketMetrics memory marketMetrics
    ) internal returns (RoutingPlan memory optimizedPlan) {
        // Start with current plan
        optimizedPlan = currentPlan;
        
        // Apply real-time optimizations based on market conditions
        if (euint128.unwrap(marketMetrics.volatilityIndex) > 500) {
            // High volatility - prefer fewer pools for faster execution
            optimizedPlan = _consolidateRouting(currentPlan);
        } else if (euint128.unwrap(marketMetrics.averageGasPrice) > 100e9) {
            // High gas - optimize for gas efficiency
            optimizedPlan = _optimizeForGas(currentPlan);
        }
        
        // Recalculate confidence score
        optimizedPlan.confidenceScore = _calculateConfidenceScore(optimizedPlan.pools, optimizedPlan.allocations);
        
        return optimizedPlan;
    }

    // =============================================================
    //                    UTILITY FUNCTIONS
    // =============================================================

    /**
     * @notice Calculate routing efficiency score
     * @param plan Routing plan to evaluate
     * @return efficiency Efficiency score (0-100)
     */
    function calculateRoutingEfficiency(RoutingPlan memory plan) internal pure returns (uint256 efficiency) {
        if (plan.poolCount == 0) return 0;
        
        // Base efficiency score
        efficiency = 70;
        
        // Bonus for optimal pool count (2-3 pools)
        if (plan.poolCount >= 2 && plan.poolCount <= 3) {
            efficiency += 15;
        }
        
        // Bonus for high confidence
        if (euint32.unwrap(plan.confidenceScore) > 80) {
            efficiency += 10;
        }
        
        // Bonus for low estimated impact
        if (euint128.unwrap(plan.estimatedImpactTotal) < 50) { // Less than 0.5%
            efficiency += 5;
        }
        
        return efficiency > 100 ? 100 : efficiency;
    }

    /**
     * @notice Get routing strategy name
     * @param strategy Strategy type
     * @return name Strategy name
     */
    function getStrategyName(uint8 strategy) internal pure returns (string memory name) {
        if (strategy == SINGLE_POOL) return "Single Pool";
        if (strategy == MULTI_POOL_SPLIT) return "Multi-Pool Split";
        if (strategy == DYNAMIC_ROUTING) return "Dynamic Routing";
        if (strategy == LIQUIDITY_OPTIMIZED) return "Liquidity Optimized";
        return "Unknown";
    }

    // =============================================================
    //                    PRIVATE FUNCTIONS
    // =============================================================

    /**
     * @notice Estimate liquidity for a pool
     * @param pool Pool to estimate
     * @return liquidity Estimated liquidity
     */
    function _estimateLiquidity(PoolKey memory pool) private returns (euint128 liquidity) {
        // Simplified estimation based on fee tier
        if (pool.fee == 500) {
            liquidity = FHE.asEuint128(5000000e18); // High liquidity for 0.05%
        } else if (pool.fee == 3000) {
            liquidity = FHE.asEuint128(10000000e18); // Highest liquidity for 0.3%
        } else if (pool.fee == 10000) {
            liquidity = FHE.asEuint128(1000000e18); // Lower liquidity for 1%
        } else {
            liquidity = FHE.asEuint128(2000000e18); // Default
        }
        
        return liquidity;
    }

    /**
     * @notice Estimate price impact for an order
     * @param pool Pool to estimate
     * @param orderAmount Order amount
     * @return impact Estimated price impact in basis points
     */
    function _estimatePriceImpact(PoolKey memory pool, euint128 orderAmount) private returns (euint128 impact) {
        euint128 liquidity = _estimateLiquidity(pool);
        
        // Simple impact calculation: impact = (orderAmount / liquidity) * 10000
        impact = FHE.div(FHE.mul(orderAmount, FHE.asEuint128(10000)), liquidity);
        
        return impact;
    }

    /**
     * @notice Estimate gas cost for pool execution
     * @param pool Pool to estimate
     * @return gasCost Estimated gas cost
     */
    function _estimateGasCost(PoolKey memory pool) private returns (euint64 gasCost) {
        // Base gas cost for swaps
        uint64 baseGas = 150000;
        
        // Additional gas for hook interactions
        if (address(pool.hooks) != address(0)) {
            baseGas += 50000;
        }
        
        return FHE.asEuint64(baseGas);
    }

    /**
     * @notice Calculate execution priority for a pool
     * @param pool Pool to evaluate
     * @return priority Priority score (higher is better)
     */
    function _calculatePriority(PoolKey memory pool) private returns (euint32 priority) {
        uint32 basePriority = 50;
        
        // Prefer standard fee tiers
        if (pool.fee == 3000) {
            basePriority += 30; // Most common tier
        } else if (pool.fee == 500) {
            basePriority += 20; // Stable pairs
        } else if (pool.fee == 10000) {
            basePriority += 10; // Exotic pairs
        }
        
        return FHE.asEuint32(basePriority);
    }

    /**
     * @notice Calculate single pool allocation (100% to best pool)
     * @param pools Available pools
     * @param orderAmount Order amount
     * @return allocations Allocation array
     */
    function _calculateSinglePoolAllocation(
        PoolKey[] memory pools,
        euint128 orderAmount
    ) private returns (uint256[] memory allocations) {
        allocations = new uint256[](pools.length);
        
        if (pools.length == 0) return allocations;
        
        // Find pool with best liquidity/impact ratio
        uint256 bestPoolIndex = 0;
        euint128 bestRatio = FHE.asEuint128(0);
        
        for (uint256 i = 0; i < pools.length; i++) {
            euint128 liquidity = _estimateLiquidity(pools[i]);
            euint128 impact = _estimatePriceImpact(pools[i], orderAmount);
            
            // Calculate ratio (liquidity / impact)
            euint128 ratio = FHE.div(liquidity, FHE.add(impact, FHE.asEuint128(1)));
            
            if (euint128.unwrap(ratio) > euint128.unwrap(bestRatio)) {
                bestRatio = ratio;
                bestPoolIndex = i;
            }
        }
        
        allocations[bestPoolIndex] = BASIS_POINTS; // 100%
        return allocations;
    }

    /**
     * @notice Calculate multi-pool allocation based on liquidity
     * @param pools Available pools
     * @param orderAmount Order amount
     * @return allocations Allocation array
     */
    function _calculateMultiPoolAllocation(
        PoolKey[] memory pools,
        euint128 orderAmount
    ) private returns (uint256[] memory allocations) {
        allocations = new uint256[](pools.length);
        
        if (pools.length == 0) return allocations;
        
        // Calculate total liquidity
        euint128 totalLiquidity = FHE.asEuint128(0);
        euint128[] memory liquidities = new euint128[](pools.length);
        
        for (uint256 i = 0; i < pools.length; i++) {
            liquidities[i] = _estimateLiquidity(pools[i]);
            totalLiquidity = FHE.add(totalLiquidity, liquidities[i]);
        }
        
        // Allocate proportionally to liquidity
        for (uint256 i = 0; i < pools.length; i++) {
            allocations[i] = (euint128.unwrap(liquidities[i]) * BASIS_POINTS) / euint128.unwrap(totalLiquidity);
        }
        
        return allocations;
    }

    /**
     * @notice Calculate dynamic allocation based on real-time conditions
     * @param pools Available pools
     * @param orderAmount Order amount
     * @return allocations Allocation array
     */
    function _calculateDynamicAllocation(
        PoolKey[] memory pools,
        euint128 orderAmount
    ) private returns (uint256[] memory allocations) {
        // For simplicity, use multi-pool allocation with adjustments
        allocations = _calculateMultiPoolAllocation(pools, orderAmount);
        
        // Apply dynamic adjustments (simplified)
        for (uint256 i = 0; i < allocations.length; i++) {
            // Prefer pools with lower fees for large orders
            if (euint128.unwrap(orderAmount) > 1000e18 && pools[i].fee > 3000) {
                allocations[i] = allocations[i] / 2; // Reduce allocation
            }
        }
        
        // Normalize to 100%
        _normalizeAllocations(allocations);
        
        return allocations;
    }

    /**
     * @notice Calculate liquidity-optimized allocation
     * @param pools Available pools
     * @param orderAmount Order amount
     * @return allocations Allocation array
     */
    function _calculateLiquidityOptimizedAllocation(
        PoolKey[] memory pools,
        euint128 orderAmount
    ) private returns (uint256[] memory allocations) {
        allocations = new uint256[](pools.length);
        
        // Focus on pools with highest liquidity to minimize impact
        for (uint256 i = 0; i < pools.length; i++) {
            euint128 liquidity = _estimateLiquidity(pools[i]);
            euint128 impact = _estimatePriceImpact(pools[i], orderAmount);
            
            // Higher allocation to pools with low impact
            uint256 impactBps = euint128.unwrap(impact);
            if (impactBps < 50) { // Less than 0.5% impact
                allocations[i] = 5000; // 50%
            } else if (impactBps < 100) { // Less than 1% impact
                allocations[i] = 3000; // 30%
            } else {
                allocations[i] = 1000; // 10%
            }
        }
        
        // Normalize to 100%
        _normalizeAllocations(allocations);
        
        return allocations;
    }

    /**
     * @notice Filter pools with non-zero allocations
     * @param pools All pools
     * @param allocations All allocations
     * @return activePools Pools with allocations
     * @return activeAllocations Non-zero allocations
     */
    function _filterActivePools(
        PoolKey[] memory pools,
        uint256[] memory allocations
    ) private pure returns (PoolKey[] memory activePools, uint256[] memory activeAllocations) {
        // Count active pools
        uint256 activeCount = 0;
        for (uint256 i = 0; i < allocations.length; i++) {
            if (allocations[i] > 0) activeCount++;
        }
        
        // Create active arrays
        activePools = new PoolKey[](activeCount);
        activeAllocations = new uint256[](activeCount);
        
        uint256 activeIndex = 0;
        for (uint256 i = 0; i < pools.length; i++) {
            if (allocations[i] > 0) {
                activePools[activeIndex] = pools[i];
                activeAllocations[activeIndex] = allocations[i];
                activeIndex++;
            }
        }
        
        return (activePools, activeAllocations);
    }

    /**
     * @notice Calculate total gas cost for routing plan
     * @param pools Pools in routing plan
     * @return totalGas Total estimated gas
     */
    function _calculateTotalGas(PoolKey[] memory pools) private returns (euint128 totalGas) {
        totalGas = FHE.asEuint128(0);
        
        for (uint256 i = 0; i < pools.length; i++) {
            euint64 poolGas = _estimateGasCost(pools[i]);
            totalGas = FHE.add(totalGas, FHE.asEuint128(euint64.unwrap(poolGas)));
        }
        
        return totalGas;
    }

    /**
     * @notice Calculate total price impact for routing plan
     * @param pools Pools in routing plan
     * @param totalAmount Total order amount
     * @param allocations Allocation percentages
     * @return totalImpact Total estimated impact
     */
    function _calculateTotalImpact(
        PoolKey[] memory pools,
        euint128 totalAmount,
        uint256[] memory allocations
    ) private returns (euint128 totalImpact) {
        totalImpact = FHE.asEuint128(0);
        
        for (uint256 i = 0; i < pools.length; i++) {
            euint128 poolAmount = FHE.div(
                FHE.mul(totalAmount, FHE.asEuint128(allocations[i])),
                FHE.asEuint128(BASIS_POINTS)
            );
            
            euint128 poolImpact = _estimatePriceImpact(pools[i], poolAmount);
            
            // Weight impact by allocation
            euint128 weightedImpact = FHE.div(
                FHE.mul(poolImpact, FHE.asEuint128(allocations[i])),
                FHE.asEuint128(BASIS_POINTS)
            );
            
            totalImpact = FHE.add(totalImpact, weightedImpact);
        }
        
        return totalImpact;
    }

    /**
     * @notice Calculate confidence score for routing plan
     * @param pools Pools in routing plan
     * @param allocations Allocation percentages
     * @return confidence Confidence score (0-100)
     */
    function _calculateConfidenceScore(
        PoolKey[] memory pools,
        uint256[] memory allocations
    ) private returns (euint32 confidence) {
        if (pools.length == 0) return FHE.asEuint32(0);
        
        uint32 baseScore = 60;
        
        // Bonus for optimal pool count
        if (pools.length == 1) baseScore += 20; // Single pool = simple
        if (pools.length == 2) baseScore += 30; // Dual pool = balanced
        if (pools.length == 3) baseScore += 25; // Triple pool = diversified
        if (pools.length > 3) baseScore += 10;   // More pools = complex
        
        return FHE.asEuint32(baseScore > 100 ? 100 : baseScore);
    }

    /**
     * @notice Consolidate routing to fewer pools for faster execution
     * @param plan Current routing plan
     * @return consolidated Consolidated plan
     */
    function _consolidateRouting(RoutingPlan memory plan) private pure returns (RoutingPlan memory consolidated) {
        // Keep only the top 2 pools by allocation
        consolidated = plan;
        
        if (plan.poolCount > 2) {
            // Find top 2 allocations
            uint256 maxAlloc1 = 0;
            uint256 maxAlloc2 = 0;
            uint256 maxIndex1 = 0;
            uint256 maxIndex2 = 0;
            
            for (uint256 i = 0; i < plan.allocations.length; i++) {
                if (plan.allocations[i] > maxAlloc1) {
                    maxAlloc2 = maxAlloc1;
                    maxIndex2 = maxIndex1;
                    maxAlloc1 = plan.allocations[i];
                    maxIndex1 = i;
                } else if (plan.allocations[i] > maxAlloc2) {
                    maxAlloc2 = plan.allocations[i];
                    maxIndex2 = i;
                }
            }
            
            // Create new arrays with top 2 pools
            consolidated.pools = new PoolKey[](2);
            consolidated.allocations = new uint256[](2);
            consolidated.pools[0] = plan.pools[maxIndex1];
            consolidated.pools[1] = plan.pools[maxIndex2];
            consolidated.allocations[0] = (maxAlloc1 * BASIS_POINTS) / (maxAlloc1 + maxAlloc2);
            consolidated.allocations[1] = BASIS_POINTS - consolidated.allocations[0];
            consolidated.poolCount = 2;
        }
        
        return consolidated;
    }

    /**
     * @notice Optimize routing for gas efficiency
     * @param plan Current routing plan
     * @return optimized Gas-optimized plan
     */
    function _optimizeForGas(RoutingPlan memory plan) private pure returns (RoutingPlan memory optimized) {
        // Prefer single pool execution to minimize gas
        optimized = plan;
        
        if (plan.poolCount > 1) {
            // Find pool with highest allocation
            uint256 maxAlloc = 0;
            uint256 maxIndex = 0;
            
            for (uint256 i = 0; i < plan.allocations.length; i++) {
                if (plan.allocations[i] > maxAlloc) {
                    maxAlloc = plan.allocations[i];
                    maxIndex = i;
                }
            }
            
            // Allocate 100% to best pool
            optimized.pools = new PoolKey[](1);
            optimized.allocations = new uint256[](1);
            optimized.pools[0] = plan.pools[maxIndex];
            optimized.allocations[0] = BASIS_POINTS;
            optimized.poolCount = 1;
        }
        
        return optimized;
    }

    /**
     * @notice Normalize allocations to sum to 100%
     * @param allocations Allocation array to normalize
     */
    function _normalizeAllocations(uint256[] memory allocations) private pure {
        uint256 total = 0;
        for (uint256 i = 0; i < allocations.length; i++) {
            total += allocations[i];
        }
        
        if (total == 0) return;
        
        for (uint256 i = 0; i < allocations.length; i++) {
            allocations[i] = (allocations[i] * BASIS_POINTS) / total;
        }
    }
}