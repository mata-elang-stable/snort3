variable "image_name" {
  default = "snort-base"
}

variable "snort_version" {
  default = str = "3.1.47.0"
}

variable "libdaq_version" {
  default = "3.0.9"
}

variable "image_repo_host" {
    default = "mataelang"
}

variable "image_tag" {
    default = ["3", "3.1", "3.1.47", "3.1.47.0"]
}

function "get_image_tag" {
  params = [image, tag, variant, version]
  result = notequal(tag, "latest") ? flatten([
        for itag in tag : concat(
            notequal(variant, "") ? ["${image_repo_host}/${image}:${itag}-${variant}"] : ["${image_repo_host}/${image}:${itag}"],
            notequal(version, "") ? ["${image_repo_host}/${image}:${itag}-${variant}-${version}"] : [],
        )
    ]) : ["${image_repo_host}/${image}:${tag}"]
}

group "default" {
  targets = [
    "snort3-debian-11",
    "snort3-debian-11-4",
    "snort3-alpine-3",
    "snort3-alpine-3-17",
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
  args = {
    SNORT_VERSION = snort_version
    LIBDAQ_VERSION = libdaq_version
  }
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
    get_image_tag(image_name, "latest", "", ""),
    get_image_tag(image_name, image_tag, "", "")
  )
}

target "snort3-debian-11-4" {
  inherits = [
    "snort3-debian"
  ]
  args = {
    DEBIAN_VERSION = "11.4"
  }
  tags = get_image_tag(image_name, image_tag, "debian", "11.4")
}

target "snort3-alpine-3" {
  inherits = [
    "snort3-alpine"
  ]
  args = {
    ALPINE_VERSION = "3"
  }
  tags = get_image_tag(image_name, image_tag, "alpine", "3")
}

target "snort3-alpine-3-17" {
  inherits = [
    "snort3-alpine"
  ]
  args = {
    ALPINE_VERSION = "3.17"
  }
  tags = get_image_tag(image_name, image_tag, "alpine", "3.17")
}
