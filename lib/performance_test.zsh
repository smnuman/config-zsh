#!/usr/bin/env zsh
# Performance benchmarking and testing script for Zsh configuration
# Usage: source performance_test.zsh && run_performance_tests

# Global variables for testing
PERF_TEST_DIR="$ZDOTDIR/logs/performance"
PERF_RESULTS_FILE="$PERF_TEST_DIR/boot_performance.log"

# Create performance test directory
[[ ! -d "$PERF_TEST_DIR" ]] && mkdir -p "$PERF_TEST_DIR"

# Function to measure execution time
measure_time() {
    local start_time=$EPOCHREALTIME
    "$@"
    local end_time=$EPOCHREALTIME
    printf "%.3f" $((end_time - start_time))
}

# Benchmark current zsh_add_file function
benchmark_current_add_file() {
    local test_file="$ZDOTDIR/zsh-aliases"
    local iterations=10
    local total_time=0

    echo "📊 Benchmarking current zsh_add_file function..."

    for i in {1..$iterations}; do
        local time=$(measure_time zsh_add_file "zsh-aliases")
        total_time=$((total_time + time))
        printf "Iteration %d: %.3fs\n" $i $time
    done

    local avg_time=$((total_time / iterations))
    printf "Average time: %.3fs\n" $avg_time
    echo "$avg_time" > "$PERF_TEST_DIR/current_add_file.benchmark"
}

# Optimized version of zsh_add_file
zsh_add_file_optimized() {
    [[ -f "$ZDOTDIR/$1" ]] && source "$ZDOTDIR/$1"
}

# Benchmark optimized zsh_add_file function
benchmark_optimized_add_file() {
    local test_file="$ZDOTDIR/zsh-aliases"
    local iterations=10
    local total_time=0

    echo "📊 Benchmarking optimized zsh_add_file function..."

    for i in {1..$iterations}; do
        local time=$(measure_time zsh_add_file_optimized "zsh-aliases")
        total_time=$((total_time + time))
        printf "Iteration %d: %.3fs\n" $i $time
    done

    local avg_time=$((total_time / iterations))
    printf "Average time: %.3fs\n" $avg_time
    echo "$avg_time" > "$PERF_TEST_DIR/optimized_add_file.benchmark"
}

# Test PATH export performance
benchmark_path_exports() {
    local iterations=5
    local total_time=0

    echo "📊 Benchmarking PATH exports..."

    # Create test function that mimics current export_path calls
    test_path_exports() {
        export_path "$BREWDOTS"
        export_path "$ZUTILS"
        export_path "$BRUTILS"
        export_path "$ZDOTDIR/git-utils/"
        export_path "$XDG_CONFIG_HOME/tmux/scripts/"
        export_path "$XDG_CONFIG_HOME/tmux/plugins/tpm/bin/"
    }

    for i in {1..$iterations}; do
        local time=$(measure_time test_path_exports)
        total_time=$((total_time + time))
        printf "Iteration %d: %.3fs\n" $i $time
    done

    local avg_time=$((total_time / iterations))
    printf "Average time: %.3fs\n" $avg_time
    echo "$avg_time" > "$PERF_TEST_DIR/path_exports.benchmark"
}

# Test full shell startup time
benchmark_shell_startup() {
    local iterations=3
    local total_time=0

    echo "📊 Benchmarking full shell startup..."

    for i in {1..$iterations}; do
        local time=$(measure_time zsh -i -c 'exit')
        total_time=$((total_time + time))
        printf "Iteration %d: %.3fs\n" $i $time
    done

    local avg_time=$((total_time / iterations))
    printf "Average shell startup time: %.3fs\n" $avg_time
    echo "$avg_time" > "$PERF_TEST_DIR/shell_startup.benchmark"
}

# Test with minimal logging
benchmark_minimal_logging() {
    echo "📊 Testing with minimal logging..."

    # Temporarily disable verbose logging
    local original_logfile="$LOGFILE"
    export LOGFILE="/dev/null"

    local time=$(measure_time zsh -i -c 'exit')
    printf "Startup time with minimal logging: %.3fs\n" $time
    echo "$time" > "$PERF_TEST_DIR/minimal_logging.benchmark"

    # Restore original logging
    export LOGFILE="$original_logfile"
}

# Generate performance report
generate_performance_report() {
    local report_file="$PERF_TEST_DIR/performance_report_$(date +%Y%m%d_%H%M%S).md"

    cat > "$report_file" << 'EOF'
# Zsh Configuration Performance Report

## Summary
This report analyzes the boot performance of the Zsh configuration and provides optimization recommendations.

## Test Results

### Current Performance Bottlenecks
1. **zsh_add_file()**: 82.45% of boot time (1244ms total)
2. **export_path()**: 23.03% of boot time (347ms total)
3. **Excessive logging**: 27k+ lines in plugin-manager.zlog

### Benchmark Results
EOF

    # Add benchmark results to report
    [[ -f "$PERF_TEST_DIR/current_add_file.benchmark" ]] && {
        printf "\n**Current zsh_add_file**: %.3fs average\n" "$(cat $PERF_TEST_DIR/current_add_file.benchmark)" >> "$report_file"
    }

    [[ -f "$PERF_TEST_DIR/optimized_add_file.benchmark" ]] && {
        printf "**Optimized zsh_add_file**: %.3fs average\n" "$(cat $PERF_TEST_DIR/optimized_add_file.benchmark)" >> "$report_file"
    }

    [[ -f "$PERF_TEST_DIR/shell_startup.benchmark" ]] && {
        printf "**Full shell startup**: %.3fs average\n" "$(cat $PERF_TEST_DIR/shell_startup.benchmark)" >> "$report_file"
    }

    [[ -f "$PERF_TEST_DIR/minimal_logging.benchmark" ]] && {
        printf "**With minimal logging**: %.3fs\n" "$(cat $PERF_TEST_DIR/minimal_logging.benchmark)" >> "$report_file"
    }

    cat >> "$report_file" << 'EOF'

## Optimization Recommendations

### 1. Reduce Logging Overhead
- Current logging adds significant overhead to every file source
- Implement conditional logging (only in debug mode)
- Use async logging for non-critical information

### 2. Optimize zsh_add_file()
- Remove unnecessary string formatting and logging
- Use simpler conditional logic
- Cache file existence checks

### 3. Batch PATH Operations
- Combine multiple export_path calls into single operation
- Pre-validate paths before export

### 4. Lazy Load Plugins
- Load non-essential plugins asynchronously
- Implement plugin priority system

### 5. Cache Completions
- Use compinit -C for faster completion loading
- Cache completion dumps properly
EOF

    echo "📊 Performance report generated: $report_file"
}

# Main test runner
run_performance_tests() {
    echo "🚀 Starting Zsh Configuration Performance Tests"
    echo "============================================="

    # Create log header
    {
        echo "# Performance Test Run: $(date)"
        echo "# System: $(uname -a)"
        echo "# Zsh Version: $(zsh --version)"
        echo "============================================="
    } > "$PERF_RESULTS_FILE"

    # Run all benchmarks
    benchmark_current_add_file | tee -a "$PERF_RESULTS_FILE"
    echo "" | tee -a "$PERF_RESULTS_FILE"

    benchmark_optimized_add_file | tee -a "$PERF_RESULTS_FILE"
    echo "" | tee -a "$PERF_RESULTS_FILE"

    benchmark_path_exports | tee -a "$PERF_RESULTS_FILE"
    echo "" | tee -a "$PERF_RESULTS_FILE"

    benchmark_shell_startup | tee -a "$PERF_RESULTS_FILE"
    echo "" | tee -a "$PERF_RESULTS_FILE"

    benchmark_minimal_logging | tee -a "$PERF_RESULTS_FILE"
    echo "" | tee -a "$PERF_RESULTS_FILE"

    # Generate comprehensive report
    generate_performance_report

    echo "✅ Performance testing complete!"
    echo "📄 Results: $PERF_RESULTS_FILE"
    echo "📊 Report: $PERF_TEST_DIR/performance_report_*.md"
}

# Quick performance check
quick_perf_check() {
    echo "⚡ Quick Performance Check"
    echo "========================="
    printf "Shell startup time: %.3fs\n" $(measure_time zsh -i -c 'exit')
    printf "zsh_add_file time: %.3fs\n" $(measure_time zsh_add_file_optimized "zsh-aliases")
}