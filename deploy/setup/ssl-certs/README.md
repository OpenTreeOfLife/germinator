## Public SSL certificates for *.opentreeoflife.org

**Needless to say, this does _not_ include private keys!**

These files are included here for convenience during deployment, they only need
    to be updated as when the certificates are about to expire.

Procedure used in May, 2018 to get new certificates.
I can't remember the exact order of operations around step 2 and 3 as
it is all a matter of filling out web forms.

  1. Log in to NameCheap and purchase a wildcard certificate.
  MTH bought their "Essential SSL Wildcard" package.
  for `*.opentreeoflife.org`

  1. Specify which of the `@opentreeoflife.org` email addresses to send a confirmation to
    and an email address to be given to the Comodo Certificate Authority.
    The NameCheap domain management tools allow you to control the email address
    that any `@opentreeoflife.org` email alias points to.

  1. To get the certificate, you need to generate a signed request to 
      send to Comodo. You do this by:
   ```
   openssl req -new -newkey rsa:2048 -nodes -keyout opentreeoflife.org.key -out opentreeoflife.org.csr
   ```
   and then answering the queries. It is very important that you:
    (A) specify `*.opentreeoflife.org` as the "Common Name" otherwise you might just
     get a cert for one machine (instead of the wildcard for the domain), and
    (B) store the private `opentreeoflife.org.key` securely. Apache needs
     to have access to that key when serving up the certificate.

  1. There are some verification steps via email and codes sent to you by Comodo, but
  soon you will get a zip archive from Comodo with a `STAR_opentreeoflife_org.ca-bundle`
  (with a chain of certs) and a simple single cert in `STAR_opentreeoflife_org.crt`

  1. NameCheap normally provides a full chain of SSL certs (which is one longer than
  the ca-bundle that you get from Comodo. This chain includes certs from our wildcard for
  `*.opentreeoflife.org` to the COMODO root certificate. 
  Sadly, this is not enough to easily build trust with some clients, so we use
  the `resolve.sh` script ([found here](https://github.com/zan/cert-chain-resolver), 
  thanks [@zakjan](https://github.com/zan)!) to fetch and append all intermediate
  certificates in the chain:
```bash
 $ ./resolve.sh STAR_opentreeoflife_org.crt STAR_opentreeoflife_org.pem
```
   Note that this script requires `wget` or `curl`, as well as `openssl` to run.

The result is a new file `STAR_opentreeoflife_org.pem`. This includes the full
chain of public certificates, and it's the file we actually specify in our
apache configuration file `001-opentree-ssl`. (See
[template](https://github.com/OpenTreeOfLife/germinator/blob/master/deploy/setup/opentree-ssl.conf)
and 
[installation script](https://github.com/OpenTreeOfLife/germinator/blob/master/deploy/restart-apache.sh)
for details.)

Since this combined certificate file is all we need, I'm leaving the other
.crt files out of version control to reduce clutter here.

**REMINDER**: that we'll occasionally need to replace the `.crt` file here, so
it's vital that in that case we re-run `resolve.sh` as described above to
generate the new `.pem` file.


