module "step1" {
  source = "../.."

  hosts  = ["a1", "a2", "a3"]
  guests = ["b1", "b2", "b3"]
}

resource "test_assertions" "step1" {
  component = "step1"

  equal "guest_hosts" {
    description = "guest_hosts"

    got = module.step1.guest_hosts
    want = tomap({
      "b1" = "a3"
      "b2" = "a2"
      "b3" = "a2"
    })

    # NOTE: When there's a similar number of hosts and guests, it's
    # pretty likely that the guests won't distribute evenly over the
    # hosts. It should get more favorable when there are significantly
    # more guests than hosts.
  }
}

module "step2" {
  source = "../.."

  hosts  = ["a1", "a2", "a4"]
  guests = ["b1", "b2", "b3"]
}

resource "test_assertions" "step2" {
  component = "step2"

  equal "guest_hosts" {
    description = "guest_hosts"

    got = module.step2.guest_hosts
    want = tomap({
      "b1" = "a4" # Reassigned, because a3 is gone
      "b2" = "a2" # Unchanged, because a2 is still present
      "b3" = "a2" # Unchanged, because a2 is still present
    })
  }
}

module "step3" {
  source = "../.."

  hosts  = ["a1", "a2", "a4"]
  guests = ["b1", "b2", "b4"]
}


resource "test_assertions" "step3" {
  component = "step3"

  equal "guest_hosts" {
    description = "guest_hosts"

    got = module.step3.guest_hosts
    want = tomap({
      "b1" = "a4" # Unchanged
      "b2" = "a2" # Unchanged
      "b4" = "a2" # A new guest
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
