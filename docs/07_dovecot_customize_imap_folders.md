<h1 align="center">Dovecot customize IMAP folders</h1>

- Copy and change file `15-mailboxes.conf`

```bash
# copy config file from docker image
cd /opt/mailserver
docker cp mailserver:/etc/dovecot/conf.d/15-mailboxes.conf ./data/dms/config/dovecot/15-mailboxes.conf

# change file 15-mailboxes.conf
vim /opt/mailserver/data/dms/config/dovecot/15-mailboxes.conf
------------------------
# NOTE: Assumes "namespace inbox" has been defined in 10-mail.conf.
namespace inbox {
  inbox = yes
  location =
  separator = /
  # === Drafts ===
  # These mailboxes are widely used and could perhaps be created automatically:
  mailbox "Drafts" {
    auto = subscribe
    special_use = \Drafts
  }
  mailbox "Entwürfe" {
    special_use = \Drafts
  }
  mailbox "Черновики" {
    special_use = \Drafts
  }
  # === Spam ===
  mailbox "Junk" {
    auto = subscribe
    special_use = \Junk
  }
  mailbox "Junk-E-Mail" {
    special_use = \Junk
  }
  mailbox "Junk E-Mail" {
    special_use = \Junk
  }
  mailbox "Spam" {
    special_use = \Junk
  }
  mailbox "Нежелательная почта" {
    special_use = \Junk
  }
  mailbox "Спам" {
    special_use = \Junk
  }
  # === Trash ===
  mailbox "Trash" {
    auto = subscribe
    special_use = \Trash
  }
  mailbox "Deleted Messages" {
    special_use = \Trash
  }
  mailbox "Deleted Items" {
    special_use = \Trash
  }
  mailbox "Gelöschte Objekte" {
    special_use = \Trash
  }
  mailbox "Gelöschte Elemente" {
    special_use = \Trash
  }
  mailbox "Papierkorb" {
    special_use = \Trash
  }
  mailbox "Удаленные" {
    special_use = \Trash
  }
  mailbox "Удаленные элементы" {
    special_use = \Trash
  }
  mailbox "Корзина" {
    special_use = \Trash
  }
  # === Sent ===
  # For \Sent mailboxes there are two widely used names. We'll mark both of
  # them as \Sent. User typically deletes one of them if duplicates are created.
  mailbox "Sent" {
    auto = subscribe
    special_use = \Sent
  }
  mailbox "Sent Messages" {
    special_use = \Sent
  }
  mailbox "Sent Items" {
    special_use = \Sent
  }
  mailbox "Gesendet" {
    special_use = \Sent
  }
  mailbox "Gesendete Objekte" {
    special_use = \Sent
  }
  mailbox "Gesendete Elemente" {
    special_use = \Sent
  }
  mailbox "Отправленные" {
    special_use = \Sent
  }
  mailbox "Отправленные элементы" {
    special_use = \Sent
  }
  # === Archive ===
  mailbox "Archive" {
    auto = subscribe
    special_use = \Archive
  }
  mailbox "Archiv" {
    special_use = \Archive
  }
  mailbox "Архив" {
    special_use = \Archive
  }
  # If you have a virtual "All messages" mailbox:
  #mailbox virtual/All {
  #  special_use = \All
  #  comment = All my messages
  #}

  # If you have a virtual "Flagged" mailbox:
  #mailbox virtual/Flagged {
  #  special_use = \Flagged
  #  comment = All my flagged messages
  #}

  # If you have a virtual "Important" mailbox:
  #mailbox virtual/Important {
  #  special_use = \Important
  #  comment = All my important messages
  #}
  prefix =
}
------------------------

### edit docker-compose.yml file
vim /opt/mailserver/docker-compose.yml
-------------------------
...
    volumes:
...
      - ./data/dms/config/dovecot/15-mailboxes.conf:/etc/dovecot/conf.d/15-mailboxes.conf:ro           # Customize IMAP Folders
...
-------------------------
```
