Nomad ACL basics
================

The core concept of the nomad's ACL is similar to well-known solutions like AWS IAM, where the policy grants permissions to resources. And each user has his own token that belongs to the predefined policy. 


In our short example, we have three groups of users.
  * admins have full privileges to each resource.
  * developers have full access to jobs in the default namespace, read-only access to cluster resources, and  no access to the system namespace
  * managament is built-in access token type working like a root in UNIX systems and standing "out of" the ACL system (quite a silly definition but it is enough for us at this moment)


**In our case, the ACL is already on and we use bootstrap token (ansible made it for us).**


```bash
# check env variables
$ env | grep -i nomad
NOMAD_TOKEN=22bSECRET-HASH-LIKE-THIS-eed5c
NOMAD_ADDR=http://localhost:4646

# check if we can communicate with nomad
$ nomad acl token self
Accessor ID  = 752xxID-HASH-LIKE-THIS-xxxxxxxb19
Secret ID    = 22bSECRET-HASH-LIKE-THIS-eed5c
Name         = Bootstrap Token
Type         = management
Global       = true
Policies     = n/a
Create Time  = 2020-02-10 10:19:04.359752478 +0000 UTC
Create Index = 33
Modify Index = 33


```
If you've received from the both commands message like is in an example, you can continue. In other case, try the lab/documentation from the official nomadproject page mentioned at the bottom of this page.



Let's start simply with generating another managament token.
```bash
$ nomad acl token create -name "token-mgmt" -type="management" | tee -a bootstrap-mgmt
Accessor ID  = 35035af4-6b77-3feb-e37b-76c3f609fa77
Secret ID    = d411470e-SECRET-MGMT-TOKEN-108a3ea26191
Name         = token-mgmt
Type         = management
Global       = false
Policies     = n/a
Create Time  = 2021-05-12 08:27:50.722324733 +0000 UTC
Create Index = 67326
Modify Index = 67326


$ export NOMAD_TOKEN=d411470e-SECRET-MGMT-TOKEN-108a3ea26191

$ nomad acl token self
Accessor ID  = 35035af4-6b77-3feb-e37b-76c3f609fa77
Secret ID    = d411470e-SECRET-MGMT-TOKEN-108a3ea26191
Name         = token-mgmt
Type         = management
Global       = false
Policies     = n/a
Create Time  = 2021-05-12 08:27:50.722324733 +0000 UTC
Create Index = 67326
Modify Index = 67326
```

So now we use our own generated management token.




In this step we need policy definition files from this repo ([policy-developers.hcl](files/acl/policy-developers.hcl) and [policy-admins.hcl](files/acl/policy-admins.hcl))
```bash
# List available policies
$ nomad acl policy list 

# Deploy developers policy
$ nomad acl policy apply -description "limited access for developers" developers ./files/acl/policy-developers.hcl

# Deploy developers policy
$ nomad acl policy apply -description "unlimited access for admins" admins ./files/acl/policy-admins.hcl

# List available policies again
$ nomad acl policy list 
Name       Description
admins     unlimited access for admins
developers limited access for developers

```

So now we have two ready to use policies and it's time to create tokens for our users.

```bash
# Create one testing developer's token
$ nomad acl token create -name "token-developer" -policy "developers" | tee -a bootstrap-developer


# Create one testing developer's token
$ nomad acl token create -name "token-admin" -policy "admins" | tee -a bootstrap-admin

```
The last thing to do is to try our new generated tokens. So let's try it in the nomad's ui 



---
More detailed descriptions and labs are at [nomadproject.io page](https://learn.hashicorp.com/collections/nomad/access-control)