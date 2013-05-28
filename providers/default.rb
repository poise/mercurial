use_inline_resources

action :sync do
  ::File.delete(hgup_file) if ::File.exist?(hgup_file)
  execute "sync repository #{new_resource.path}" do
    not_if "hg identify #{new_resource.path}"
    command "hg clone --rev #{new_resource.reference} #{hg_connection_command} #{new_resource.repository} #{new_resource.path} && touch #{hgup_file}"
    creates hgup_file
    notifies :run, "execute[set ownership #{new_resource.path}]"
    notifies :run, "execute[set permissions #{new_resource.path}]"
  end
  execute "check incoming changes #{new_resource.path}" do
    command "hg incoming --rev #{new_resource.reference} #{hg_connection_command}  #{new_resource.repository} && touch #{hgup_file} || true"
    cwd new_resource.path
    creates hgup_file
    notifies :run, "execute[pull #{new_resource.path}]"
  end
  execute "pull #{new_resource.path}" do
    command "hg pull --rev #{new_resource.reference} #{hg_connection_command} #{new_resource.repository}"
    cwd new_resource.path
    only_if { ::File.exist?(hgup_file) }
    action :nothing
    notifies :run, "execute[update #{new_resource.path}]"
  end
  execute "update #{new_resource.path}" do
    command "hg update"
    cwd new_resource.path
    action :nothing
    notifies :run, "execute[set ownership #{new_resource.path}]"
    notifies :run, "execute[set permissions #{new_resource.path}]"
  end
  execute "set ownership #{new_resource.path}" do
    command "chown -R #{new_resource.owner}:#{new_resource.group} #{new_resource.path}"
    action :nothing
  end
  execute "set permissions #{new_resource.path}" do
    command "chmod -R #{new_resource.mode} #{new_resource.path}"
    only_if { new_resource.mode }
  end
end

action :clone do
  ::File.delete(hgup_file) if ::File.exist?(hgup_file)
  execute "clone repository #{new_resource.path}" do
    command "hg clone --rev #{new_resource.reference} #{hg_connection_command} #{new_resource.repository} #{new_resource.path} && touch #{hgup_file}"
    not_if "hg identify #{new_resource.path}"
    creates hgup_file
    notifies :run, "execute[set permission #{new_resource.path}]"
    notifies :run, "execute[set ownership #{new_resource.path}]"
  end
  execute "set ownership #{new_resource.path}" do
    command "chown -R #{new_resource.owner}:#{new_resource.group} #{new_resource.path}"
    action :nothing
  end
  execute "set permission #{new_resource.path}" do
    command "chmod -R #{new_resource.mode} #{new_resource.path}"
    only_if { new_resource.mode }
  end
end
