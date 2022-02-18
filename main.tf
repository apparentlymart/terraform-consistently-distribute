
variable "hosts" {
  type = set(string)

  validation {
    # We're spreading the hosts around a 1024-degree circle below, and the
    # closer we get to that number the more likely we'll end up with two
    # hosts sharing the same angle and thus getting assigned no hosts.
    # We'll make that limit explicit here so that we don't just succeed and
    # do something daft.
    condition     = length(var.hosts) < 256
    error_message = "This algorithm becomes less effective with more than 255 hosts."
  }

  validation {
    # We're spreading the hosts around a 1024-degree circle below, and the
    # closer we get to that number the more likely we'll end up with two
    # hosts sharing the same angle and thus getting assigned no hosts.
    # We'll make that limit explicit here so that we don't just succeed and
    # do something daft.
    condition     = length(var.hosts) > 0
    error_message = "Must specify at least one host."
  }
}

variable "guests" {
  type = set(string)
}

locals {
  # NOTE: 1024 is a practical limit here because Terraform's range() function
  # won't generate a range larger than that, and so if we go larger we risk
  # sometimes generating arcs on the circle that are too long to generate.
  circum = 1024

  host_hashes = tomap({
    for s in var.hosts : s => parseint(md5(s), 16) % local.circum
  })
  guest_hashes = tomap({
    for s in var.guests : s => parseint(md5(s), 16) % local.circum
  })

  hosts_order = tolist([
    for k, s in tomap({
      for s, h in local.host_hashes : format("%03x%s", h, s) => s
    }) :
    s
  ])

  host_angles = tomap({
    for s, h in local.host_hashes : s => h - local.host_hashes[local.hosts_order[0]]
  })
  guest_angles_tmp = tomap({
    for s, h in local.guest_hashes : s => h - local.host_hashes[local.hosts_order[0]]
  })
  guest_angles = tomap({
    for s, a in local.guest_angles_tmp : s => a >= 0 ? a : local.circum + a
  })

  angle_hosts = flatten([
    [
      for i, s in local.hosts_order : [
        for x in range(local.host_angles[s], try(local.host_angles[local.hosts_order[i + 1]], local.circum)) : s
      ]
    ]
  ])

  guest_hosts = tomap({
    for s in var.guests : s => local.angle_hosts[local.guest_angles[s]]
  })
}

output "hosts" {
  value = var.hosts
}

output "guests" {
  value = var.guests
}

output "guest_hosts" {
  value = local.guest_hosts
}

output "debug_angles" {
  value = {
    # NOTE: intentionally using hashes rather than angles here because
    # the angles are all rotated to put the lowest one at zero, whereas
    # the hashes stay consistent even if the lowest hash changes.
    hosts  = local.host_hashes
    guests = local.guest_hashes
  }

  description = "A debug-only structure, subject to change in future minor releases, describing the arbitrary \"angles\" assigned to each host and guest, from 0 to 1023."
}
