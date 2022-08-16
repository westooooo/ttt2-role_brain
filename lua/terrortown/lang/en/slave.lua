local L = LANG.GetLanguageTableReference("en")

-- GENERAL ROLE LANGUAGE STRINGS
L[SLAVE.name] = "Slave"
L["target_" .. SLAVE.name] = "Slave"
L["ttt2_desc_" .. SLAVE.name] = [[You are now a Slave. Help your new teammate win the round!]]
L["body_found_" .. SLAVE.abbr] = "They were a Slave."
L["search_role_" .. SLAVE.abbr] = "This person was a Slave!"

L["weapon_slavedeagle_name"] = "Slavedeagle"
L["weapon_slavedeagle_desc"] = "Shoot a player to make him your Slave."

L["ttt2_slave_shot"] = "Successfully shot {name} as your Slave!"
L["ttt2_slave_were_shot"] = "You were shot as a Slave by {name}!"
L["ttt2_slave_sameteam"] = "You can't shoot someone from your own team as Slave!"
L["ttt2_slave_ply_killed"] = "Your Slave Deagle cooldown was reduced by {amount} seconds."
L["ttt2_slave_recharged"] = "Your Slave Deagle has been recharged."
