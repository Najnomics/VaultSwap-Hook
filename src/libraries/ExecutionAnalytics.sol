// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {euint128, euint32, euint64, ebool, FHE} from "@fhenixprotocol/cofhe-contracts/FHE.sol";

/**
 * @title ExecutionAnalytics
 * @notice Advanced execution quality measurement and performance tracking
 * @dev Provides comprehensive analytics for institutional-grade execution reporting
 */
library ExecutionAnalytics {
    
    // =============================================================
    //                    CONSTANTS
    // =============================================================

    /// @notice Quality score thresholds
    uint256 public constant EXCELLENT_THRESHOLD = 95;
    uint256 public constant GOOD_THRESHOLD = 85;
    uint256 public constant FAIR_THRESHOLD = 70;
    uint256 public constant POOR_THRESHOLD = 50;

    /// @notice Slippage thresholds in basis points
    uint256 public constant LOW_SLIPPAGE = 25;      // 0.25%
    uint256 public constant MEDIUM_SLIPPAGE = 100;  // 1%
    uint256 public constant HIGH_SLIPPAGE = 500;    // 5%
    uint256 public constant EXTREME_SLIPPAGE = 1000; // 10%

    /// @notice Execution time thresholds in seconds
    uint256 public constant FAST_EXECUTION = 30;
    uint256 public constant NORMAL_EXECUTION = 300;   // 5 minutes
    uint256 public constant SLOW_EXECUTION = 1800;    // 30 minutes

    // =============================================================
    //                    STRUCTS
    // =============================================================

    struct QualityMetrics {
        uint256 executionScore;      // 0-100 overall quality score
        uint256 slippageScore;       // 0-100 slippage performance
        uint256 timingScore;         // 0-100 timing performance  
        uint256 gasEfficiencyScore;  // 0-100 gas efficiency
        uint256 impactScore;         // 0-100 market impact score
    }

    struct ExecutionReport {
        bytes32 orderId;
        address user;
        uint256 timestamp;
        uint256 amountIn;
        uint256 amountOut;
        uint256 expectedOutput;
        uint256 slippageBps;
        uint256 executionTimeSeconds;
        uint256 gasUsed;
        uint256 qualityScore;
        string qualityGrade;
        bool targetsMet;
    }

    struct PerformanceSummary {
        uint256 totalOrders;
        uint256 successfulOrders;
        uint256 averageQuality;
        uint256 averageSlippage;
        uint256 averageExecutionTime;
        uint256 totalVolumeProcessed;
        uint256 gasEfficiency;
        uint256 lastUpdated;
    }

    // =============================================================
    //                    EVENTS
    // =============================================================

    event QualityScoreCalculated(bytes32 indexed orderId, uint256 score, string grade);
    event PerformanceReport(address indexed user, uint256 avgQuality, uint256 totalOrders);
    event ThresholdBreached(bytes32 indexed orderId, string metric, uint256 value, uint256 threshold);

    // =============================================================
    //                    QUALITY SCORING
    // =============================================================

    /**
     * @notice Calculate comprehensive execution quality score
     * @param expectedOutput Expected output amount
     * @param actualOutput Actual output amount received
     * @param executionTime Time taken for execution
     * @param gasUsed Gas consumed for execution
     * @param maxMarketImpact Maximum acceptable market impact
     * @return qualityScore Overall quality score (0-100)
     */
    function calculateQualityScore(
        uint256 expectedOutput,
        uint256 actualOutput,
        uint256 executionTime,
        uint256 gasUsed,
        uint256 maxMarketImpact
    ) internal pure returns (uint256 qualityScore) {
        QualityMetrics memory metrics = QualityMetrics({
            executionScore: 0,
            slippageScore: _calculateSlippageScore(expectedOutput, actualOutput),
            timingScore: _calculateTimingScore(executionTime),
            gasEfficiencyScore: _calculateGasEfficiencyScore(gasUsed),
            impactScore: _calculateImpactScore(expectedOutput, actualOutput, maxMarketImpact)
        });

        // Weighted average of all metrics
        qualityScore = (
            metrics.slippageScore * 40 +      // 40% weight on slippage
            metrics.timingScore * 25 +        // 25% weight on timing
            metrics.gasEfficiencyScore * 20 + // 20% weight on gas efficiency
            metrics.impactScore * 15          // 15% weight on market impact
        ) / 100;

        return qualityScore;
    }

    /**
     * @notice Get quality grade from score
     * @param score Quality score (0-100)
     * @return grade Letter grade (A+, A, B, C, D, F)
     */
    function getQualityGrade(uint256 score) internal pure returns (string memory grade) {
        if (score >= 98) return "A+";
        if (score >= EXCELLENT_THRESHOLD) return "A";
        if (score >= GOOD_THRESHOLD) return "B";
        if (score >= FAIR_THRESHOLD) return "C";
        if (score >= POOR_THRESHOLD) return "D";
        return "F";
    }

    /**
     * @notice Calculate slippage in basis points
     * @param expectedOutput Expected output amount
     * @param actualOutput Actual output amount
     * @return slippageBps Slippage in basis points
     */
    function calculateSlippage(
        uint256 expectedOutput,
        uint256 actualOutput
    ) internal pure returns (uint256 slippageBps) {
        if (expectedOutput == 0) return 0;
        
        if (actualOutput >= expectedOutput) {
            // Positive slippage (better than expected)
            return 0;
        }
        
        uint256 slippageAmount = expectedOutput - actualOutput;
        slippageBps = (slippageAmount * 10000) / expectedOutput;
        
        return slippageBps;
    }

    /**
     * @notice Check if execution meets quality targets
     * @param qualityScore Calculated quality score
     * @param targetScore Target quality score
     * @param slippageBps Actual slippage in basis points
     * @param maxSlippageBps Maximum acceptable slippage
     * @return targetsMet Whether all targets were met
     */
    function checkQualityTargets(
        uint256 qualityScore,
        uint256 targetScore,
        uint256 slippageBps,
        uint256 maxSlippageBps
    ) internal pure returns (bool targetsMet) {
        return qualityScore >= targetScore && slippageBps <= maxSlippageBps;
    }

    // =============================================================
    //                    PERFORMANCE TRACKING
    // =============================================================

    /**
     * @notice Create execution report for an order
     * @param orderId Order identifier
     * @param user User address
     * @param amountIn Input amount
     * @param amountOut Actual output amount
     * @param expectedOutput Expected output amount
     * @param executionTime Execution time in seconds
     * @param gasUsed Gas consumed
     * @return report Complete execution report
     */
    function createExecutionReport(
        bytes32 orderId,
        address user,
        uint256 amountIn,
        uint256 amountOut,
        uint256 expectedOutput,
        uint256 executionTime,
        uint256 gasUsed
    ) internal view returns (ExecutionReport memory report) {
        uint256 slippageBps = calculateSlippage(expectedOutput, amountOut);
        uint256 qualityScore = calculateQualityScore(expectedOutput, amountOut, executionTime, gasUsed, 500); // 5% max impact
        
        report = ExecutionReport({
            orderId: orderId,
            user: user,
            timestamp: block.timestamp,
            amountIn: amountIn,
            amountOut: amountOut,
            expectedOutput: expectedOutput,
            slippageBps: slippageBps,
            executionTimeSeconds: executionTime,
            gasUsed: gasUsed,
            qualityScore: qualityScore,
            qualityGrade: getQualityGrade(qualityScore),
            targetsMet: checkQualityTargets(qualityScore, 85, slippageBps, 100) // 85% quality, 1% max slippage
        });
        
        return report;
    }

    /**
     * @notice Update user performance summary
     * @param currentSummary Current performance summary
     * @param newReport New execution report to include
     * @return updatedSummary Updated performance summary
     */
    function updatePerformanceSummary(
        PerformanceSummary memory currentSummary,
        ExecutionReport memory newReport
    ) internal view returns (PerformanceSummary memory updatedSummary) {
        updatedSummary = currentSummary;
        
        // Update counters
        updatedSummary.totalOrders += 1;
        if (newReport.targetsMet) {
            updatedSummary.successfulOrders += 1;
        }
        
        // Update running averages
        updatedSummary.averageQuality = _updateAverage(
            currentSummary.averageQuality,
            newReport.qualityScore,
            currentSummary.totalOrders,
            updatedSummary.totalOrders
        );
        
        updatedSummary.averageSlippage = _updateAverage(
            currentSummary.averageSlippage,
            newReport.slippageBps,
            currentSummary.totalOrders,
            updatedSummary.totalOrders
        );
        
        updatedSummary.averageExecutionTime = _updateAverage(
            currentSummary.averageExecutionTime,
            newReport.executionTimeSeconds,
            currentSummary.totalOrders,
            updatedSummary.totalOrders
        );
        
        // Update totals
        updatedSummary.totalVolumeProcessed += newReport.amountIn;
        updatedSummary.gasEfficiency = _calculateCumulativeGasEfficiency(
            currentSummary.gasEfficiency,
            newReport.gasUsed,
            newReport.amountIn
        );
        
        updatedSummary.lastUpdated = block.timestamp;
        
        return updatedSummary;
    }

    /**
     * @notice Calculate success rate percentage
     * @param summary Performance summary
     * @return successRate Success rate as percentage (0-100)
     */
    function calculateSuccessRate(PerformanceSummary memory summary) internal pure returns (uint256 successRate) {
        if (summary.totalOrders == 0) return 0;
        return (summary.successfulOrders * 100) / summary.totalOrders;
    }

    /**
     * @notice Get performance grade based on summary metrics
     * @param summary Performance summary
     * @return grade Overall performance grade
     */
    function getPerformanceGrade(PerformanceSummary memory summary) internal pure returns (string memory grade) {
        uint256 successRate = calculateSuccessRate(summary);
        
        if (summary.averageQuality >= EXCELLENT_THRESHOLD && successRate >= 95) return "A+";
        if (summary.averageQuality >= GOOD_THRESHOLD && successRate >= 90) return "A";
        if (summary.averageQuality >= FAIR_THRESHOLD && successRate >= 80) return "B";
        if (summary.averageQuality >= POOR_THRESHOLD && successRate >= 70) return "C";
        if (successRate >= 50) return "D";
        return "F";
    }

    // =============================================================
    //                    BENCHMARK COMPARISONS
    // =============================================================

    /**
     * @notice Compare execution against market benchmarks
     * @param actualSlippage Actual slippage experienced
     * @param marketAvgSlippage Market average slippage
     * @param executionTime Actual execution time
     * @param marketAvgTime Market average execution time
     * @return improvement Percentage improvement over market (can be negative)
     */
    function calculateMarketImprovement(
        uint256 actualSlippage,
        uint256 marketAvgSlippage,
        uint256 executionTime,
        uint256 marketAvgTime
    ) internal pure returns (int256 improvement) {
        // Calculate slippage improvement (lower is better)
        int256 slippageImprovement = marketAvgSlippage > 0 ? 
            int256((marketAvgSlippage - actualSlippage) * 100) / int256(marketAvgSlippage) : int256(0);
        
        // Calculate time improvement (lower is better)
        int256 timeImprovement = marketAvgTime > 0 ? 
            int256((marketAvgTime - executionTime) * 100) / int256(marketAvgTime) : int256(0);
        
        // Weighted average (60% slippage, 40% time)
        improvement = (slippageImprovement * 60 + timeImprovement * 40) / 100;
        
        return improvement;
    }

    /**
     * @notice Generate compliance metrics for institutional reporting
     * @param summary Performance summary
     * @return complianceScore Compliance score (0-100)
     * @return riskLevel Risk level (Low, Medium, High)
     */
    function generateComplianceMetrics(
        PerformanceSummary memory summary
    ) internal pure returns (uint256 complianceScore, string memory riskLevel) {
        uint256 successRate = calculateSuccessRate(summary);
        
        // Base compliance score from success rate and quality
        complianceScore = (successRate + summary.averageQuality) / 2;
        
        // Adjust for slippage control
        if (summary.averageSlippage <= LOW_SLIPPAGE) {
            complianceScore += 5; // Bonus for excellent slippage control
        } else if (summary.averageSlippage > HIGH_SLIPPAGE) {
            complianceScore = complianceScore > 15 ? complianceScore - 15 : 0; // Penalty for poor slippage
        }
        
        // Determine risk level
        if (complianceScore >= 90 && summary.averageSlippage <= MEDIUM_SLIPPAGE) {
            riskLevel = "Low";
        } else if (complianceScore >= 70 && summary.averageSlippage <= HIGH_SLIPPAGE) {
            riskLevel = "Medium";
        } else {
            riskLevel = "High";
        }
        
        return (complianceScore > 100 ? 100 : complianceScore, riskLevel);
    }

    // =============================================================
    //                    PRIVATE FUNCTIONS
    // =============================================================

    /**
     * @notice Calculate slippage score component
     * @param expectedOutput Expected output
     * @param actualOutput Actual output
     * @return score Slippage score (0-100)
     */
    function _calculateSlippageScore(uint256 expectedOutput, uint256 actualOutput) private pure returns (uint256 score) {
        if (expectedOutput == 0) return 100;
        
        uint256 slippageBps = calculateSlippage(expectedOutput, actualOutput);
        
        if (slippageBps == 0) return 100;
        if (slippageBps <= LOW_SLIPPAGE) return 95;
        if (slippageBps <= MEDIUM_SLIPPAGE) return 85;
        if (slippageBps <= HIGH_SLIPPAGE) return 70;
        if (slippageBps <= EXTREME_SLIPPAGE) return 50;
        return 25; // Very poor slippage
    }

    /**
     * @notice Calculate timing score component
     * @param executionTime Execution time in seconds
     * @return score Timing score (0-100)
     */
    function _calculateTimingScore(uint256 executionTime) private pure returns (uint256 score) {
        if (executionTime <= FAST_EXECUTION) return 100;
        if (executionTime <= NORMAL_EXECUTION) return 85;
        if (executionTime <= SLOW_EXECUTION) return 70;
        return 50; // Very slow execution
    }

    /**
     * @notice Calculate gas efficiency score component
     * @param gasUsed Gas consumed
     * @return score Gas efficiency score (0-100)
     */
    function _calculateGasEfficiencyScore(uint256 gasUsed) private pure returns (uint256 score) {
        // Base score that decreases with gas usage
        if (gasUsed <= 150000) return 100;      // Excellent efficiency
        if (gasUsed <= 300000) return 90;       // Good efficiency
        if (gasUsed <= 500000) return 80;       // Average efficiency
        if (gasUsed <= 750000) return 70;       // Below average
        if (gasUsed <= 1000000) return 60;      // Poor efficiency
        return 50; // Very poor efficiency
    }

    /**
     * @notice Calculate market impact score component
     * @param expectedOutput Expected output
     * @param actualOutput Actual output
     * @param maxMarketImpact Maximum acceptable impact in basis points
     * @return score Market impact score (0-100)
     */
    function _calculateImpactScore(
        uint256 expectedOutput,
        uint256 actualOutput,
        uint256 maxMarketImpact
    ) private pure returns (uint256 score) {
        uint256 slippageBps = calculateSlippage(expectedOutput, actualOutput);
        
        if (slippageBps == 0) return 100;
        if (slippageBps <= maxMarketImpact / 4) return 95;  // Very low impact
        if (slippageBps <= maxMarketImpact / 2) return 85;  // Low impact
        if (slippageBps <= maxMarketImpact) return 75;      // Acceptable impact
        if (slippageBps <= maxMarketImpact * 2) return 60;  // High impact
        return 40; // Excessive impact
    }

    /**
     * @notice Update running average with new value
     * @param currentAverage Current average value
     * @param newValue New value to include
     * @param oldCount Previous count of values
     * @param newCount New count of values
     * @return updatedAverage Updated average
     */
    function _updateAverage(
        uint256 currentAverage,
        uint256 newValue,
        uint256 oldCount,
        uint256 newCount
    ) private pure returns (uint256 updatedAverage) {
        if (oldCount == 0) return newValue;
        
        updatedAverage = ((currentAverage * oldCount) + newValue) / newCount;
        return updatedAverage;
    }

    /**
     * @notice Calculate cumulative gas efficiency metric
     * @param currentEfficiency Current efficiency metric
     * @param newGasUsed New gas amount
     * @param newVolumeProcessed New volume processed
     * @return updatedEfficiency Updated efficiency metric
     */
    function _calculateCumulativeGasEfficiency(
        uint256 currentEfficiency,
        uint256 newGasUsed,
        uint256 newVolumeProcessed
    ) private pure returns (uint256 updatedEfficiency) {
        // Simple efficiency metric: volume per gas unit
        if (newGasUsed == 0) return currentEfficiency;
        
        uint256 newEfficiency = newVolumeProcessed / newGasUsed;
        
        // Average with existing efficiency (simplified)
        return (currentEfficiency + newEfficiency) / 2;
    }
}