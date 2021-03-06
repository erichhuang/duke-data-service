var Dredd = require('dredd');

// allow self-signed certs
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

// suppress warning message if more than 10 listeners are added to an event - this is needed here to suppress
// warning messages from the node-rest-client package...
require('events').EventEmitter.defaultMaxListeners = Infinity;

configuration = {
  server: process.env.HOST_NAME, // your URL to API endpoint the tests will run against
  //For debug: export HOST_NAME=https://dukeds-dev.herokuapp.com/api/v1
  //Get JWT: https://dukeds-dev.herokuapp.com/apiexplorer
  //export MY_GENERATED_JWT=
  options: {

    'path': ['./apiary.apib'],  // Required Array if Strings; filepaths to API Blueprint files, can use glob wildcards

    'dry-run': false, // Boolean, do not run any real HTTP transaction
    'names': false,   // Boolean, Print Transaction names and finish, similar to dry-run

    'level': 'info', // String, log-level (info, silly, debug, verbose, ...)
    'silent': false, // Boolean, Silences all logging output

    'only': [//Auth
             //"Authorization Roles > Authorization Roles collection > List roles", //r2g
             //"Authorization Roles > Authorization Role instance > View role",     //r2g
             //Current Users
             //"Current User > Current User instance > View current user",          //r2g
             //Users
             //"Users > Users collection > List users",
             //"Users > User instance > View user",
             //System Permissions
             //"System Permissions > System Permissions collection > List system permissions",
             //"System Permissions > System Permission instance > Grant system permission",
             //"System Permissions > System Permission instance > View system permission",
             //"System Permissions > System Permission instance > Revoke system permission",
             //Projects
            //  "Projects > Projects collection > Create project",
            //  "Projects > Projects collection > List projects",
            //  "Projects > Project instance > View project",
            //  "Projects > Project instance > Update project",
            //  "Projects > Project instance > Delete project",
             //Project Permissions
            //  "Project Permissions > Project Permissions collection > List project permissions",
            //  "Project Permissions > Project Permission instance > Grant project permission",
            //  "Project Permissions > Project Permission instance > View project permission",
            //  "Project Permissions > Project Permission instance > Revoke project permission",
             //Project Roles
            //  "Project Roles > Project Roles collection > List project roles",
            //  "Project Roles > Project Role instance > View project role",
             //Affiliates
            //  "Affiliates > Affiliates collection > List affiliates",
            //  "Affiliates > Affiliate instance > Associate affiliate",
            //  "Affiliates > Affiliate instance > View affiliate",
            //  "Affiliates > Affiliate instance > Delete affiliate",
             //Storage Providers
            //  "Storage Providers > Storage Providers collection > List storage providers",
            //  "Storage Providers > Storage Provider instance > View storage provider",
             //Folders
            //  "Folders > Folders collection > Create folder",
            //  "Folders > Folder instance > View folder",
            //  "Folders > Folder instance > Delete folder",
            //  "Folders > Folder instance > Move folder",
            //  "Folders > Folder instance > Rename folder",
            //Uploads
            // "Uploads > Uploads collection > Initiate chunked upload",
            // "Uploads > Uploads collection > List chunked uploads",
            // "Uploads > Upload instance > View chunked upload",
            // "Uploads > Upload instance > Get pre-signed chunk URL",
            // "Uploads > Upload instance > Complete chunked file upload",
            //files
            // "Files > Files collection > Create file",
            // "Files > File instance > View file",
            // "Files > File instance > Delete file",
            // "Files > File instance > Get pre-signed download URL",
            // "Files > File instance > Move file",
            // "Files > File instance > Rename file",
             //"Search Project/Folder Children > Search Project Children > Search Project Children", //r2g
             //"Search Project/Folder Children > Search Folder Children > Search Folder Children"    //r2g

            ], // Array of Strings, run only transaction that match these names

    'header': ['Accept: application/json', 'Authorization: '.concat(process.env.MY_GENERATED_JWT)], // Array of Strings, these strings are then added as headers (key:value) to every transaction
    'user': null,    // String, Basic Auth credentials in the form username:password

    'hookfiles': [ //'99_learnclient.js',
                  '01_auth_hooks.js',                 //r2g
                  '02_current_user_hooks.js',         //r2g
                  '03_users_hooks.js',                //r2g
                  '04_system_permissions_hooks.js',   //r2g
                  '05_projects_hooks.js',             //r2g
                  '06_project_permissions_hooks.js', //r2g
                  '07_project_roles_hooks.js',       //r2g
                  '08_affiliates_hooks.js',          //r2g
                  '09_storage_providers_hooks.js',   //r2g
                  '10_folders_hooks.js',             //r2g
                  '11_uploads_hooks.js',             //r2g
                  '12_files_hooks.js',
                  '13_search_project_folder_hooks.js'
                ], // Array of Strings, filepaths to files containing hooks (can use glob wildcards)

    'reporter': [], // Array of possible reporters, see folder src/reporters

    'output': [],    // Array of Strings, filepaths to files used for output of file-based reporters

    'inline-errors': false, // Boolean, If failures/errors are display immediately in Dredd run

    'color': true,
    'timestamp': false
  }
  // 'emitter': EventEmitterInstance // optional - listen to test progress, your own instance of EventEmitter

  // 'hooksData': {
  //   'pathToHook' : '...'
  // }

  // 'data': {
  //   'path/to/file': '...'
  //}
}

var dredd = new Dredd(configuration);

dredd.run(function (err, stats) {
  // err is present if anything went wrong
  // otherwise stats is an object with useful statistics
});
