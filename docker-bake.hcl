variable "IMAGE_NAME" {
  default = "snort-base"
}

variable "SNORT_VERSION" {
  default = "3.1.39.0"
}

variable "LIBDAQ_VERSION" {
  default = "3.0.9"
}

function "get_image_tag" {
  params = [image, tag, variant, version]
  result = flatten([
    for host in [
      "mfscy"
      ] : concat(
      notequal(variant, "") ?
      ["${host}/${image}:${tag}-${variant}"] :
      ["${host}/${image}:${tag}"],
      notequal(version, "") ?
      ["${host}/${image}:${tag}-${variant}-${version}"] :
      [],
    )
  ])
}

group "default" {
  targets = [
    "snort3-debian-11",
    "snort3-debian-11-4",
    "snort3-alpine-3",
    "snort3-alpine-3-16",
  ]
}

target "virtual-default" {
  context = "."
  labels = {
    // "net.mataelang.image.source" = "https://github.com/mata-elang-stable",
  }
}

target "virtual-platforms" {
  platforms = [
    "linux/amd64",
    // "linux/386",
    "linux/arm64",
    // "linux/arm/v7",
    // "linux/ppc64le",
    // "linux/s390x",
  ]
}

target "virtual-debian" {
  dockerfile = "dockerfiles/debian.dockerfile"
}

target "virtual-alpine" {
  dockerfile = "dockerfiles/alpine.dockerfile"
}

target "snort3-default" {
  inherits = [
    "virtual-default",
    "virtual-platforms",
  ]
}

target "snort3-debian" {
  inherits = [
    "snort3-default",
    "virtual-debian"
  ]
}

target "snort3-alpine" {
  inherits = [
    "snort3-default",
    "virtual-alpine"
  ]
}

target "snort3-debian-11" {
  inherits = [
    "snort3-debian"
  ]
  args = {
    DEBIAN_VERSION = "11"
  }
  tags = concat(
    get_image_tag("${IMAGE_NAME}", "latest", "", ""),
    get_image_tag("${IMAGE_NAME}", "3", "", ""),
    get_image_tag("${IMAGE_NAME}", "3", "debian", "11"),
    get_image_tag("${IMAGE_NAME}", "3.1", "debian", "11"),
    get_image_tag("${IMAGE_NAME}", "3.1.39", "debian", "11"),
    get_image_tag("${IMAGE_NAME}", "3.1.39.0", "debian", "11"),
  )
}

target "snort3-debian-11-4" {
  inherits = [
    "snort3-debian"
  ]
  args = {
    DEBIAN_VERSION = "11.4"
  }
  tags = concat(
    get_image_tag("${IMAGE_NAME}", "3", "debian", "11.4"),
    get_image_tag("${IMAGE_NAME}", "3.1", "debian", "11.4"),
    get_image_tag("${IMAGE_NAME}", "3.1.39", "debian", "11.4"),
    get_image_tag("${IMAGE_NAME}", "3.1.39.0", "debian", "11.4"),
  )
}

target "snort3-alpine-3" {
  inherits = [
    "snort3-alpine"
  ]
  args = {
    ALPINE_VERSION = "3"
  }
  tags = concat(
    get_image_tag("${IMAGE_NAME}", "3", "alpine", "3"),
    get_image_tag("${IMAGE_NAME}", "3.1", "alpine", "3"),
    get_image_tag("${IMAGE_NAME}", "3.1.39", "alpine", "3"),
    get_image_tag("${IMAGE_NAME}", "3.1.39.0", "alpine", "3"),
  )
}

target "snort3-alpine-3-16" {
  inherits = [
    "snort3-alpine"
  ]
  args = {
    ALPINE_VERSION = "3.16"
  }
  tags = concat(
    get_image_tag("${IMAGE_NAME}", "3", "alpine", "3.16"),
    get_image_tag("${IMAGE_NAME}", "3.1", "alpine", "3.16"),
    get_image_tag("${IMAGE_NAME}", "3.1.39", "alpine", "3.16"),
    get_image_tag("${IMAGE_NAME}", "3.1.39.0", "alpine", "3.16"),
  )
}
