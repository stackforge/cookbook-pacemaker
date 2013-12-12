name "pacemaker-active"
description "pacemaker active."

override_attributes(
  "pacemaker" => {
    "services" => {
      "apache2" => {
        "vip" => "10.0.111.5",
        "active" => "ubuntu1-1004.vm"
      },
      "mysql" => {
        "vip" => "10.0.111.7",
        "passive" => ["ubuntu1-1004.vm"]
      }
    }
  }
  )

run_list(
  "recipe[pacemaker::master]",
  "recipe[pacemaker::services]"
  )
