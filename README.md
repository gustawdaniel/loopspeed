# Loopspeed - Performance Analysis of Empty Loops in 16 Languages

Benchmarking project measuring and analyzing empty loop performance and program startup overhead across 16 different programming languages.

## Project Structure

- `inc/` - Benchmark implementations for each programming language (`inc.c`, `inc.cpp`, `inc.py`, `inc.r`, etc.)
- `util/generate_parameters.py` - Non-linear regression data fitting using SciPy (`uv run util/generate_parameters.py`)
- `util/generate_plots.py` - Plot generator using Matplotlib (`uv run util/generate_plots.py`)
- `util/publish_to_blog.sh` - Publishes generated plots directly to the blog public directory
- `test.sh` - Project test suite using `shunit2`
- `.github/workflows/test.yml` - CI/CD pipeline for GitHub Actions

## Installation & Running Locally

1. Install dependencies:
   ```bash
   bash install.sh
   ```

2. Load parameters into SQLite:
   ```bash
   perl util/parameters_load.pl
   ```

3. Run benchmarks:
   ```bash
   bash inc.bash -t 2
   ```

4. Run tests:
   ```bash
   bash test.sh
   ```

5. Generate parameters & plots with Python (`uv`):
   ```bash
   uv run util/generate_parameters.py
   uv run util/generate_plots.py
   ```

## Local GitHub Actions Testing with `act`

You can run GitHub Actions workflows locally using [act](https://github.com/nektos/act):

```bash
# Install act on Arch Linux
paru -S act

# Run GitHub Actions workflow locally with modern Ubuntu image
act -P ubuntu-latest=catthehacker/ubuntu:act-latest
```