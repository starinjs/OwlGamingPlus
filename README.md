# OwlGamingPlus

## Setup

The **ideal setup** is the following:

- Linux Operating System (64 bit)
- Up-to-date MTA server
- Local MariaDB server with remote connections blocked
- Security:
  - Minimal port forwarding: use a firewall to only allow MTA ports and never open the MySQL port (default 3306)
  - Remote SSH access: disable password authentication and set up SSH key authentication

The following steps are for setting up the **MySQL database**:

1. Install a MySQL server like [MariaDB](https://mariadb.org/)
2. Configure a MySQL username and password that will be used by the MTA server
3. Access the [data/mysql](/data/mysql) folder, which contains the necessary initial setup files
4. Create a new database with a name of your choice and preferably UTF8 charset
5. Run the `mta.sql` script to create the tables in your new database
6. Run the `data.sql` script to populate the tables created with initial data

The following steps are for setting up the **MTA server**:

1. Install the latest MTA 1.6 Nightly server [(from https://nightly.mtasa.com/)](https://nightly.mtasa.com/) on Windows/Linux [(Tutorial here)](https://wiki.multitheftauto.com/wiki/Server_Manual#Installing_the_server)
2. Clone the repository into `server/mods/deathmatch/resources/`. Resources are contained inside the `[gamemode]` folder
3. Access the [data/config](/data/config) folder, which contains the necessary initial setup files
4. Configure the server's `settings.xml` and `mtaserver.conf` according to the templates
    - Fill in the MySQL connection settings with the correct credentials that you defined in MySQL server installation

