# OwlGamingPlus

## Setup

The ideal setup is an up-to-date MTA Server running on a Linux Machine (64 bit) with a MariaDB server also running on the same machine.

The following steps are for setting up the **MySQL database**:

1. Access the [data](/data/mysql) folder, which contains the necessary initial setup files
2. Create a new database with a name of your choice and preferably UTF8 charset
3. Run the `mta.sql` script to create the tables in your new database
4. Run the `data.sql` script to populate the tables created with initial data

The following steps are for setting up the **MTA server**:

1. Install the latest MTA 1.6 Nightly server [(from https://nightly.mtasa.com/)](https://nightly.mtasa.com/) on Windows/Linux [(Tutorial here)](https://wiki.multitheftauto.com/wiki/Server_Manual#Installing_the_server)
2. Clone the repository into `server/mods/deathmatch/resources/`. Resources are contained inside the `[gamemode]` folder
3. Access the [data/config](/data/config) folder, which contains the necessary initial setup files
4. Configure the server's `settings.xml` and `mtaserver.conf` according to the templates
    - Fill in the MySQL connection settings with the correct credentials

