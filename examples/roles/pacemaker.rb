name "pacemaker-passive"
description "pacemaker passive."

override_attributes(
  "pacemaker" => {
    "services" => {
    }
  }
  )

run_list(
  "recipe[pacemaker::client]",
  "recipe[pacemaker::services]"
  )
