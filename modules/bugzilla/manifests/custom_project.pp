class bugzilla::custom_project (

) {

        $project = hiera('bugzilla::project', {} )
        create_resources(bugzilla::project, $project)
}
