
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

  # If we assign each host only one angle then it's quite likely that they'll
  # be distributed poorly, such that some hosts have a very small arc and
  # thus get assigned very few guests.
  # To improve distribution, we give each host multiple arcs of different
  # locations and lengths on the circle. The arcs will still be of different
  # sizes, so distribution still isn't totally even, but this makes it
  # better than it would be with only one arc each.
  virtual_count = 4

  virtual_pairs = flatten([
    for s in var.hosts : [
      for x in range(0, local.virtual_count) : {
        host = s
        idx  = x
      }
    ]
  ])
  virtual_hosts = tomap({
    for pair in flatten([
      for s in var.hosts : [
        for x in range(0, local.virtual_count) : {
          host = s
          idx  = x
        }
      ]
    ]) :
    format("%x%s", pair.idx, pair.host) => pair.host
  })

  host_hashes = tomap({
    for vs, s in local.virtual_hosts : vs => parseint(md5(vs), 16) % local.circum
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
    for s in var.guests : s => local.virtual_hosts[local.angle_hosts[local.guest_angles[s]]]
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
