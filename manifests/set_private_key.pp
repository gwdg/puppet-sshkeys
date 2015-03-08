# == Defined Type: sshkeys::set_private_key
#
#   Set a private key for a user.
#
# === Parameters
#
#   [*local_user*]
#     The user who will receive the key.
#
#   [*remote_user*]
#     The user of the key being obtained.
#
#   [*ensure*]
#     Status of the key.
#
#   [*target*]
#     The destination file.
#
define sshkeys::set_private_key (
  $local_user,
  $remote_user,
  $ensure  = 'present',
  $target  = undef
) {

  # Parse the name
  $parts = split($remote_user, '@')
  $remote_username = $parts[0]
  $remote_node     = downcase($parts[1])

  $home = getvar("::home_${local_user}")

  # Get the key
  if $remote_node =~ /\./ {
    $results = query_facts("fqdn=\"${remote_node}\"", ["sshprivkey_${remote_username}"])
  } else {
    $results = query_facts("hostname=\"${remote_node}\"", ["sshprivkey_${remote_username}"])
  }
  if is_hash($results) and has_key($results, $remote_node) {
    $key = $results[$remote_node]["sshprivkey_${remote_username}"]
    if ($key !~ /BEGIN\s+(\w+)\s+PRIVATE/) {
      err("Can't parse key from ${remote_user}")
      notify { "Can't parse key from ${remote_user}. Skipping": }
    } else {
      $keytype = downcase($1)

      # Figure out the target
      if $target {
        $target_real = $target
      } else {
        $target_real = "${home}/.ssh/id_${keytype}"
      }

      file { $target_real:
        content => $key,
        mode    => '0600',
        owner   => $local_user,
        group   => $local_user,
        ensure  => $ensure,
      }

    }
  } else {
    notify { "Private key from ${remote_username}@${remote_node} (for local user ${local_user}) not available yet. Skipping": }
  }
}
