Preservica Data Deleter Plugin
------------------------------

This is an ArchivesSpace plugin that introduces a new background job that deletes
Preservica generated records from an ArchivesSpace instance.

It was developed by Hudson Molonglo for Yale University.

# Getting Started

Download the latest release from the Releases tab in Github:

  https://github.com/hudmol/preservica_data_deleter/releases

Unzip the release and move it to:

    /path/to/archivesspace/plugins

Unzip it:

    $ cd /path/to/archivesspace/plugins
    $ unzip preservica_data_deleter-vX.X.zip

Enable the plugin by editing the file in `config/config.rb`:

    AppConfig[:plugins] = ['some_plugin', 'preservica_data_deleter']

(Make sure you uncomment this line (i.e., remove the leading '#' if present))

See also:

  https://github.com/archivesspace/archivesspace/blob/master/plugins/README.md


# How it works

This plugin is designed to run on a test instance of ArchivesSpace. When data is copied from
a production instance of ArchivesSpace that is integrated with Preservica into the test instance
it will contain records created by the production Preservica instance. This plugin is designed
to simplify the removal of those records in the test instance.

It enables this by introducing a new background job type. To run a Preservica Data Deleter job,
select Create > Background Job > Preservica Data Deleter

By default, when a Preservica Data Deleter job is run it will simply report on the records it
finds that would be deleted. In order to actually delete data, the job submitter must check the
'delete' checkbox and enter a confirmation string. This is designed to minimize the risk of accidentally
deleting data. However, extreme caution should always be exercised when running this job.

