RHEL_VERSION ?= 9.4

KERNEL_VERSION ?= ''
BUILD_ARCH ?= x86_64

CUDA_VERSION ?= 12.3.2

DRIVER_VERSION ?= ''
DRIVER_TYPE ?= passthrough

CONTAINER_TOOL ?= podman
DOCKERFILE ?= Containerfile

IMAGE_REGISTRY=quay.io/fabiendupont
IMAGE_NAME=rhel-bootc-nvidia

BUILDER_USER ?= $(shell git config --get user.name)
BUILDER_EMAIL ?= $(shell git config --get user.email)

.PHONY: image image-push

# Build the image
image:
	@echo "!=== Building image ${IMAGE_REGISTRY}/${IMAGE_NAME}:${RHEL_VERSION}-${DRIVER_VERSION} ===!"
	${CONTAINER_TOOL} build \
		--build-arg RHEL_VERSION=${RHEL_VERSION} \
		--build-arg CUDA_VERSION=${CUDA_VERSION} \
		--build-arg BUILD_ARCH=${BUILD_ARCH} \
		--build-arg TARGET_ARCH=${TARGET_ARCH} \
		--build-arg KERNEL_VERSION=${KERNEL_VERSION} \
		--build-arg DRIVER_VERSION=${DRIVER_VERSION} \
		--build-arg BUILDER_USER="${BUILDER_USER}" \
		--build-arg BUILDER_EMAIL=${BUILDER_EMAIL} \
		--build-arg DRIVER_TOOLKIT_IMAGE=${DRIVER_TOOLKIT_IMAGE} \
		--build-arg DRIVER_TYPE=${DRIVER_TYPE} \
		--tag ${IMAGE_REGISTRY}/${IMAGE_NAME}:${RHEL_VERSION}-${DRIVER_VERSION} \
		--progress=plain \
		--file ${DOCKERFILE} .

image-push:
	@echo "!=== Pushing image ===!"
	${CONTAINER_TOOL} push \
		${IMAGE_REGISTRY}/${IMAGE_NAME}:${RHEL_VERSION}-${DRIVER_VERSION}

