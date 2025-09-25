
// variables
variable "OWNER_NAME" {
  type = string
  default = "feederbox826"
}

variable "IMAGE_NAME" {
  type = string
  default = "webp-watch"
}

// targets
target "alpine" {
  context = "."
  dockerfile = "Dockerfile"
  tags = [
    "ghcr.io/${OWNER_NAME}/${IMAGE_NAME}:latest"
  ]
  platforms = ["linux/amd64", "linux/arm64"]
  cache-to = [{ type = "gha", mode = "max" }]
  cache-from = [{ type = "gha" }]
}

target "alpine-debug" {
  inherits = ["alpine"]
  tags = [
    "${IMAGE_NAME}"
  ]
  platforms = ["linux/amd64"]
  cache-to = [{ type = "inline", mode = "max" }]
  cache-from = [{ type = "inline" }]
} 
