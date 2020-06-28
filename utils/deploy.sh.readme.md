# Purpose

There are a number of files in the installation-script/utils folder beginning with deploy*. Their purpose is to help you deploy jars in a transparent, scripted and repeatable way.

# Standards:

* Create a repository dedicated to deployment artifacts (like code only for jars and deployment scripts). Example: deploy_chuboe
* Create tickets in your tool of choice (github, jira, google docs, etc..) for each enhancement/change.
* Copy the deploy.sh.template (located in this directory) into the root directory of your deployment repository.
* Create a folder in the deployment repo per ticket. The folder name will be the ticket number.
* Each ticket folder has the current artifcts included.
* All depricated artifacts for any given ticket/folder will be moved to the ticket's Old folder.
* Folder's names - capiitalize first letter or word. Examples: 2Pack, Log
* In case of deployment issue, add logs to the ticket's Log folder
* All 2Packs not already included in plugins, will be added the ticket's 2Pack folder. Adhere to the iDempiere naming stardard demonstarted here: https://wiki.idempiere.org/en/NF5.1_Automatic_External_Packin
* When performing a production release, create a new ticket and folder in the deployment repo. The purpose of the ticket is to document the release.
	* Once a ticket is released to production, the folder will be renamed to include the release name and date, and it will be moved to the repo's root/Closed folder.
* If a ticket needs work after it is released to production, simply create a new root folder with the original ticket number containing the newly created deployment artifacts. When this new ticket is released, follow the same release rename/move process listed above. When the second ticket is released to production, you will have two tickets with the same ticket numnber prefix but contiaining different artifacts and different suffix.

****** Example ******

The example is best viewed via a terminal

├── 51022R
│   ├── 2Pack
│   │   ├── 202005062200_ZitoMedia_Docsis_MTA_Request_Category.zip
│   │   └── 202005071243_ZitoMedia_Docsis_Provision_SysConfig.zip
│   ├── com.zitomedia.provision.conklin_6.0.20.202006082140.jar
│   ├── com.zitomedia.provision.docsis_6.0.13.202006181252.jar
│   ├── com.zitomedia.provision.model_6.0.7.202006181252.jar
│   ├── com.zitomedia.provision.process_6.0.13.202006181252.jar
│   ├── com.zitomedia.provision.serviceprovider_6.0.15.202006181252.jar
│   ├── com.zitomedia.requestserviceaction_6.0.2.202006082140.jar
│   ├── deploy.sh
│   └── Old
│       ├── com.zitomedia.provision.docsis_6.0.12.202006082140.jar
│       ├── com.zitomedia.provision.docsis_6.0.9.202005111327.jar
│       ├── com.zitomedia.provision.model_6.0.6.202006082140.jar
│       ├── com.zitomedia.provision.process_6.0.10.202006082140.jar
│       ├── com.zitomedia.provision.process_6.0.6.202005111853.jar
│       ├── com.zitomedia.provision.serviceprovider_6.0.12.202006082140.jar
│       ├── com.zitomedia.provision.serviceprovider_6.0.13.202006101912.jar
│       └── com.zitomedia.provision.serviceprovider_6.0.9.202005151846.jar
