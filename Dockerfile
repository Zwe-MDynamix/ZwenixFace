# Stage 1: Use a standard Python image
FROM python:3.10-slim

# Set environment variables for non-interactive commands
ENV PYTHONUNBUFFERED 1
ENV APP_HOME /home/user/app

# --- 1. Install System Dependencies (as root) ---
# This block installs build tools and libraries required by dlib and OpenCV.
# It replaces the problematic 'libatlas-base-dev' with standard packages.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    pkg-config \
    # Optimized linear algebra (replaces libatlas-base-dev)
    libopenblas-dev \
    liblapack-dev \
    # Core display and I/O libraries for OpenCV/dlib
    libx11-dev \
    libgtk-3-dev \
    libgl1 \
    libsm6 \
    libxext6 \
    # Boost libraries for dlib/C++ extension
    libboost-python-dev \
    libboost-system-dev \
    libboost-filesystem-dev \
    # Other miscellaneous dependencies
    git \
    git-lfs \
    ffmpeg \
    rsync \
    # Clean up the package lists
    && rm -rf /var/lib/apt/lists/*

# --- 2. Setup Application Directory and User ---
RUN useradd -m -u 1000 user
WORKDIR ${APP_HOME}
RUN chown -R user:user ${APP_HOME}
USER user

# --- 3.1 Fix $PATH (Crucial for Streamlit/pip scripts) ---
# Adds the local bin directory to PATH so 'streamlit' can be found.
ENV PATH="/home/user/.local/bin:$PATH"

# --- 3.2 Set a custom root for InsightFace to prevent FileExistsError on startup.
ENV INSIGHTFACE_ROOT=/home/user/app/.insightface_cache
#
# --- 4. Install Python Dependencies (as user) ---
# Ensure your requirements.txt pins numpy<2.0.0
COPY --chown=user:user requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# --- 5. Copy Application Code ---
COPY --chown=user:user . .

# --- 6. Set Container Runtime Configuration ---
EXPOSE 8501

# Use the robust 'python -m streamlit' command to avoid 'executable not found' error
CMD ["python", "-m", "streamlit", "run", "app.py"]
