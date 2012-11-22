action :sync do
  ::File.delete(hgupFile) if ::File.exist?(hgupFile)
  execute "sync repository #{new_resource.path}" do    
    not_if "hg identify #{new_resource.path}"
    command "hg clone -e 'ssh -i #{new_resource.key} -o StrictHostKeyChecking=no' -r #{new_resource.reference} #{new_resource.repository} #{new_resource.path} && touch #{hgupFile}"
    creates hgupFile
    notifies :run, "execute[set ownership]"
    notifies :run, "execute[set permissions]"
  end
  execute "check incoming changes" do
    command "hg incoming --rev #{new_resource.reference} --ssh 'ssh -i #{new_resource.key} -o StrictHostKeyChecking=no'  #{new_resource.repository} && touch #{hgupFile} || true"
    cwd new_resource.path
    creates hgupFile
    notifies :run, "execute[pull]"
  end
  execute "pull" do
    command "hg pull --rev #{new_resource.reference} --ssh 'ssh -i #{new_resource.key} -o StrictHostKeyChecking=no' #{new_resource.repository}"
    cwd new_resource.path
    only_if { ::File.exist?(hgupFile) }
    action :nothing
    notifies :run, "execute[update]"
  end
  execute "update" do
    command "hg update"
    cwd new_resource.path
    action :nothing
    notifies :run, "execute[set ownership]"
    notifies :run, "execute[set permissions]"
  end
  execute "set ownership" do
    command "chown -R #{new_resource.owner}:#{new_resource.group} #{new_resource.path}"
    action :nothing
  end
  execute "set permissions" do
    command "chmod -R #{new_resource.mode} #{new_resource.path}"
    action :nothing
  end
  if ::File.exist?(hgupFile)
    new_resource.updated_by_last_action(true)
    ::File.delete(hgupFile)
  else
    new_resource.updated_by_last_action(false)
  end
end
 
action :clone do
  ::File.delete(hgupFile) if ::File.exist?(hgupFile)
  execute "clone repository #{new_resource.path}" do
    command "hg clone --rev #{new_resource.reference} --ssh 'ssh -i #{new_resource.key} -o StrictHostKeyChecking=no' #{new_resource.repository} #{new_resource.path} && touch #{hgupFile}"
    not_if "hg identify #{new_resource.path}"
    creates hgupFile
    notifies :run, "execute[set permission]"
    notifies :run, "execute[set ownership]"
  end
  execute "set ownership" do
    command "chown -R #{new_resource.owner}:#{new_resource.group} #{new_resource.path}"
    action :nothing
  end
  execute "set permission" do
    command "chmod -R #{new_resource.mode} #{new_resource.path}"
    action :nothing
  end
  if ::File.exist?(hgupFile)
    new_resource.updated_by_last_action(true)
    ::File.delete(hgupFile)
  else
    new_resource.updated_by_last_action(false)
  end
end
