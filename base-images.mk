# Base image inputs shared by local builds and CI. Updated by wodby/images.
# Each digest identifies the complete multi-platform image index.
BASE_IMAGE_REPOSITORY := wodby/php
BASE_IMAGE_VERSION_SUFFIX :=

BASE_IMAGE_DIGEST_8.2 := sha256:2af7ec70be8b2c49b67ca933185f7573da27c1ea85d0432719639f5a030a2c01
BASE_IMAGE_DIGEST_8.2-r15 := sha256:29f23aeabd30a28b7c1a18952763e7e034cbfb6b7fb46fab641c9a99cdace07e
BASE_IMAGE_DIGEST_8.4-apache := sha256:4016959fdb5b25f7420d0096251ed76c43f280c6a1bba21d1f1d0745381d80cd
BASE_IMAGE_DIGEST_8.4-apache-r15 := sha256:52da76a7a2cd04a42c0ddbb57f39cd87385c8f40eb89d790d5f79d76b1243a58

# Fail before building when a version or variant has no reviewed pin.
BASE_IMAGE = $(BASE_IMAGE_REPOSITORY):$(BASE_IMAGE_TAG)@$(or $(BASE_IMAGE_DIGEST_$(BASE_IMAGE_TAG)),$(error No base image digest for $(BASE_IMAGE_REPOSITORY):$(BASE_IMAGE_TAG); update base-images.mk))
