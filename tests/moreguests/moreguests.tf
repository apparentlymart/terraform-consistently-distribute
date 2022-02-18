module "step1" {
  source = "../.."

  hosts  = ["a1", "a3"]
  guests = ["b1", "b2", "b3", "b4", "b5"]
}

resource "test_assertions" "step1" {
  component = "step1"

  equal "guest_hosts" {
    description = "guest_hosts"

    got = module.step1.guest_hosts
    want = tomap({
      "b1" = "a3"
      "b2" = "a3"
      "b3" = "a3"
      "b4" = "a3"
      "b5" = "a1"
    })

    # NOTE: When there's a similar number of hosts and guests, it's
    # pretty likely that the guests won't distribute very evenly over the
    # hosts. It should get more favorable when there are significantly
    # more guests than hosts.
  }
}

module "step2" {
  source = "../.."

  hosts  = ["a1", "a3"]
  guests = ["b1", "b2", "b3", "b5"]
}

resource "test_assertions" "step2" {
  component = "step2"

  equal "guest_hosts" {
    description = "guest_hosts"

    got = module.step2.guest_hosts
    want = tomap({
      "b1" = "a3"
      "b2" = "a3"
      "b3" = "a3"
      # guest b4 is gone
      "b5" = "a1"
    })
  }
}

module "step3" {
  source = "../.."

  hosts  = ["a1", "a2", "a3"]
  guests = ["b1", "b2", "b3", "b5"]
}

resource "test_assertions" "step3" {
  component = "step3"

  equal "guest_hosts" {
    description = "guest_hosts"

    got = module.step3.guest_hosts
    want = tomap({
      "b1" = "a3" # Unchanged
      "b2" = "a2" # Reassigned to new host a2
      "b3" = "a2" # Reassigned to new host a2
      "b5" = "a1" # Unchanged
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
