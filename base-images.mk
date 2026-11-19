# Base image inputs shared by local builds and CI. Updated by wodby/images.
# Each digest identifies the complete multi-platform image index.
BASE_IMAGE_REPOSITORY := wodby/php
BASE_IMAGE_VERSION_SUFFIX :=

BASE_IMAGE_DIGEST_8.2 := sha256:ef28007ad8e8df2ef1b1da139520c851cb65419c288b3ca6224f61981f623164
BASE_IMAGE_DIGEST_8.2-r16 := sha256:37c8490d6857c58f93b249ce57bddebec0dd18721150dd8179e16a88cf373c92
BASE_IMAGE_DIGEST_8.4-apache := sha256:f17066cb529311555af5cbf335e3ce0bd4166224c675d203ed535c6e2491a460
BASE_IMAGE_DIGEST_8.4-apache-r16 := sha256:d2f03879f274baaf2bd12db4ad34ae5cc58366abe5d4450f473ddfbde88c5dc1

# Fail before building when a version or variant has no reviewed pin.
BASE_IMAGE = $(BASE_IMAGE_REPOSITORY):$(BASE_IMAGE_TAG)@$(or $(BASE_IMAGE_DIGEST_$(BASE_IMAGE_TAG)),$(error No base image digest for $(BASE_IMAGE_REPOSITORY):$(BASE_IMAGE_TAG); update base-images.mk))
