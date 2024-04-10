# Image-based RHEL with NVIDIA GPU drivers and container runtime

The procedure is based on [building custom kmod packages](https://github.com/NVIDIA/yum-packaging-precompiled-kmod) to allow support for a wide range of kernel versions.

**Prerequisites**:

* A Red Hat account with access to Red Hat Hybrid Cloud Console and Red Hat Subscription Management (RHSM).
* A machine for each architecture that the image is built for. Cross-compilation is not supported.

## Image build

We want to build the image for RHEL 9.4, which is the only version available
as an OCI image. Let's state that clearly in the `RHEL_VERSION` environment
version.

```
export RHEL_VERSION='9.4'
```

### Accessing the Red Hat content

Create a
[Red Hat Customer Portal Activation Key](https://access.redhat.com/articles/1378093)
and note your Red Hat Subscription Management (RHSM) organization ID. These
will be used to install packages during a build. Save the values to file,
e.g. `$HOME/rhsm_org` and `$HOME/rhsm_activationkey`, and export the paths to these
files.

```
export RHSM_ORG_FILE=$HOME/rhsm_org
export RHSM_ACTIVATIONKEY_FILE=$HOME/rhsm_activationkey
```

Next we’ll need to authenticate to registry.redhat.io. If you do not have a
Red Hat account,visit https://access.redhat.com/terms-based-registry and
click “New service account”. From there click the name of the new entry and
copy/paste the “docker login” instructions in the terminal, replacing the
docker command with podman. Full instructions are
[here](https://access.redhat.com/RegistryAuthentication) if more information
is needed.

### Find out the Driver Toolkit (DTK) image for your target Red Hat kernel, e.g.:

*The Driver Toolkit (DTK from now on) is a container image in the
OpenShift payload which is meant to be used as a base image on
which to build driver containers. The Driver Toolkit image contains
the kernel packages commonly required as dependencies to build or
install kernel modules as well as a few tools needed in driver
containers. The version of these packages will match the kernel
version running on the RHCOS nodes in the corresponding OpenShift
release.* -- [Driver Toolkit](https://github.com/openshift/driver-toolkit/)

With that in mind, we can start defining some environment variables
and get the Driver Toolkit image for the version of OpenShift we
need to compile the drivers for.

   First, we define the version of OpenShift and the architecture.

***Note*** - Red Hat Enterprise Linux 9 provides a kernel compiled
with 64k page size for `aarch64` architecture. For these builds,
the version of the kernel is suffixed with `+64k`. Hence, we need
to differentiate the target architecture, which is `aarch64` and
the build kernel which is either empty or `+64k`.

```
export BUILD_ARCH='x86_64'
export TARGET_ARCH=$(echo "${BUILD_ARCH}" | sed 's/+64k//')
```

We can now get the Driver Toolkit image for our target RHEL kernel.

***Note*** - The current Driver Toolkit images are tied to OpenShift.
Therefore, we will use a custom Driver Toolkit image repository that is tied
to the kernel version.

```
podman pull --arch=${TARGET_ARCH} registry.redhat.io/rhel9-beta/rhel-bootc:9.4
export KERNEL_VERSION=$(podman inspect registry.redhat.io/rhel9-beta/rhel-bootc:9.4 | jq -r '.[0].Config.Labels["ostree.linux"]')
export KERNEL_VERSION_NOARCH=$(echo "${KERNEL_VERSION}" | sed "s/\.${TARGET_ARCH}//")
export DRIVER_TOOLKIT_IMAGE="quay.io/fabiendupont/driver-toolkit:${KERNEL_VERSION_NOARCH}"
```

### Set NVIDIA environment variables.

```
export CUDA_VERSION=12.3.2
export DRIVER_EPOCH=1
export DRIVER_VERSION=550.54.15
```

### Customize the builder info

The default container management tool is Podman (`podman`). You can
override it to use Docker by setting the `CONTAINER_TOOL` environment
variable to `docker`.

The default registry is `quay.io/fabiendupont`. You can override it to your
own registry via the `IMAGE_REGISTRY` environment variable.

The default image name is `rhel-bootc-nvidia`. You can override is by
setting the `IMAGE_NAME` environment variable.

You can also override `BUILDER_USER` and/or `BUILDER_EMAIL`. Otherwise,
your Git username and email will be used.

See the [Makefile](Makefile) for all available variables.

### Build and push the image

```
make image image-push
```
