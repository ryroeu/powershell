# RepAdmin Commands for Troubleshooting

## Forces the KCC on the targeted domain controller to immediately recalculate its inbound replication topology
repadmin.exe /kcc

## Allows an admin to view or modify the Password Replication Policy (PRP) for Read-only Domain Controllers (RODCs)
repadmin.exe /prp

## Displays inbound replication requests that the domain controller needs to issue to become consistent with its source replication partners
repadmin.exe /queue

## Triggers the immediate replication of the specified directory partition to the destination domain controller from the source domain controller
repadmin.exe /replicate

## Replicates a single object between any two domain controllers that have common directory partitions
repadmin.exe /replsingleobj

## Quickly and concisely summarizes the replication state and relative health of an Active Directory forest”
repadmin.exe /replsummary

## Triggers replication of passwords for the specified user(s) from the source domain controller to one or more RODCs”
repadmin.exe /rodcpwdrepl

## Displays the attributes of an object
repadmin.exe /showattr

## Displays the last time the domain controller(s) was backed up
repadmin.exe /showbackup

## Displays the replication metadata for a specified object stored in Active Directory, such as attribute ID, version number, originating and local Update Sequence Number (USN), and originating server's GUID and data and time stamp
repadmin.exe /showobjmeta

## Displays the replication status and when the specified domain controller last attempted to inbound replicate Active Directory partitions
repadmin.exe /showrepl

## Displays the highest committed Update Sequence Number (USN) that the targeted domain controller's copy of Active Directory shows as committed for itself and its transitive partners
repadmin.exe /showutdvec

##Synchronizes a specified domain controller with all replication partners
repadmin.exe /syncall

## Optional for Authentication
## DOMAIN\UserName
/u:

## Password for the user account
/pw:
