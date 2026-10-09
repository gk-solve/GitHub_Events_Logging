provider "azurerm" {
  features {
  }
  subscription_id                 = "5f04c695-b6c6-4f21-8e29-acdd0aa5160c"
  environment                     = "public"
  use_msi                         = false
  use_cli                         = true
  use_oidc                        = false
  resource_provider_registrations = "none"
}
