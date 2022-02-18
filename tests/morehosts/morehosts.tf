module "step1" {
  source = "../.."

  hosts  = ["a1", "a2", "a3", "a4", "a5"]
  guests = ["b1", "b2"]
}

resource "test_assertions" "step1" {
  component = "step1"

  equal "guest_hosts" {
    description = "guest_hosts"

    got = module.step1.guest_hosts
    want = tomap({
      "b1" = "a2"
      "b2" = "a4"
    })
  }
}

module "step2" {
  source = "../.."

  hosts  = ["a1", "a2", "a3", "a4", "a5"]
  guests = ["b1", "b2", "b3"]
}

resource "test_assertions" "step2" {
  component = "step2"

  equal "guest_hosts" {
    description = "guest_hosts"

    got = module.step2.guest_hosts
    want = tomap({
      "b1" = "a2" # Unchanged
      "b2" = "a4" # Unchanged
      "b3" = "a3" # New
    })
  }
}

module "step3" {
  source = "../.."

  hosts  = ["a1", "a2", "a3", "a5"]
  guests = ["b1", "b2", "b3"]
}

resource "test_assertions" "step3" {
  component = "step3"

  equal "guest_hosts" {
    description = "guest_hosts"

    got = module.step3.guest_hosts
    want = tomap({
      "b1" = "a2" # Unchanged
      "b2" = "a3" # Reassigned, because a4 is removed
      "b3" = "a3" # Unchanged
    })
  }
}

output "results" {
  value = [
    module.step1,
    module.step2,
    module.step3,
  ]
}

terraform {
  required_version = "~> 1.1.0"

  required_providers {
    test = {
      source = "terraform.io/builtin/test"
    }
  }
}
