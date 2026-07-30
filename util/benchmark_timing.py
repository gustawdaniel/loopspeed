#!/usr/bin/env python3
import os
import subprocess
import numpy as np

def run_benchmarks(num_runs=30, loop_count=4000000):
    print(f"Running {num_runs} iterations for both timing methods (loop_count={loop_count})...")
    
    timing_sh_results = []
    usr_time_results = []

    for i in range(num_runs):
        # Method 1: util/timing.sh
        cmd_timing = f"bash util/timing.sh bash inc/inc.bash {loop_count}"
        res_timing = subprocess.check_output(cmd_timing, shell=True, text=True).strip()
        t1 = float(res_timing)
        timing_sh_results.append(t1)

        # Method 2: time -f "%e" (simulated via TIMEFORMAT="%2R" or 2-decimal precision)
        cmd_usr = f'TIMEFORMAT="%2R"; (time bash inc/inc.bash {loop_count} >/dev/null) 2>&1'
        res_usr = subprocess.check_output(cmd_usr, shell=True, text=True).strip()
        t2 = float(res_usr)
        usr_time_results.append(t2)

        print(f"Run {i+1}/{num_runs}: util/timing.sh = {t1:.6f}s, /usr/bin/time = {t2:.2f}s")

    t1_arr = np.array(timing_sh_results)
    t2_arr = np.array(usr_time_results)

    print("\n=== Benchmark Results ===")
    print(f"util/timing.sh:   mean = {t1_arr.mean():.3f}s, std = {t1_arr.std():.3f}s")
    print(f"/usr/bin/time %e: mean = {t2_arr.mean():.3f}s, std = {t2_arr.std():.3f}s")

    # Save to npz for generate_plots.py
    np.savez("log/timing_comparison.npz", timing_sh=t1_arr, usr_time=t2_arr)
    print("Saved benchmark results to log/timing_comparison.npz")

if __name__ == "__main__":
    run_benchmarks(num_runs=30, loop_count=4000000)
