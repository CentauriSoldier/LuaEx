--[[!
    @fqxn Dox.Statics.BlockTags
    @desc This is a list of all built-in <a href="#Classes.Utility.Dox.BlockTag">BlockTags</a>.
    <br>While subclasses (parsers) <i>may</i> provide their own, additional BlockTags, these are always guaranteed to be available.
!]]
local _bRequired            = true;
local _bMultipleAllowed     = true;
local _bCombined            = true;

return {
    --TODO allow modification and ordering
    --[[!
    @fqxn Dox.Statics.Built-in BlockTags.FQXN
    @desc   Display: <strong>FQXN</strong><br>
            Aliases:<br><ul><li>fqxn</li></ul>
            Required: <b>true</b><br>
            Multiple Allowed: <b>false</b><br>
            Combined: <b>false</b><br>
            #Columns: <b>1</b>
            Has Column Wrapper(s): <b>false</b><br>
            <br><br>
            The <b>Fully</b> <b>Q</b>ualified Do<b>x</b> <b>N</b>ame (FQXN) is a required BlockTag that tells Dox how to organize the block in the final output.<br>
            It can be thought of as a unique web address, providing a unique landing page for all items within a block.<br>
            In addition, FQXNs can be used to create anchor links.
    @ex
    --create an anchor link in a comment block to another item.
    --\[\[!
        \@fqxn MyProject.MyClass.MyMethods.Method1
        \@desc This method does neat stuff then calls &lt;a href="MyProject.MyClass.MyMethods.Method2"&gt;Method2&lt;/a&gt;
    !\]\]
    !]]
    DoxBlockTag(    {"fqxn"},                                                   "FQXN",
                    _bRequired,     -_bMultipleAllowed),
    --[[!
    @fqxn Dox.Statics.Built-in BlockTags.Scope
    @desc Display: <strong>Scope</strong><br>
          Aliases:<br><ul><li>scope</li></ul>
          Required: <b>false</b><br>
          Multiple Allowed: <b>false</b><br>
          Combined: <b>false</b><br>
          #Columns: <b>1</b><br>
          Has Column Wrapper(s): <b>false</b><br>
    !]]
    DoxBlockTag(    {"scope"},                                                  "Scope",
                    -_bRequired,    -_bMultipleAllowed,   -_bCombined,      0,
                    {"<em>", "</em>"}),
    --[[!
    @fqxn Dox.Statics.Built-in BlockTags.Visibility
    @desc Display: <strong>Visibility</strong><br>
                   Aliases:<br><ul><li>vis</li>visi<li>visibility</li></ul>
                   Required: <b>false</b><br>
                   Multiple Allowed: <b>false</b><br>
                   Combined: <b>false</b><br>
                   #Columns: <b>1</b><br>
                   Has Column Wrapper(s): <b>false</b><br>
    !]]
    DoxBlockTag(    {"vis", "visi", "visibility"},                              "Visibility",
                    -_bRequired,    -_bMultipleAllowed),
    --[[!
    @fqxn Dox.Statics.Built-in BlockTags.Description
    @desc Display: <strong>Description</strong><br>
                   Aliases:<br><ul><li>des</li>desc<li>description</li></ul>
                   Required: <b>false</b><br>
                   Multiple Allowed: <b>false</b><br>
                   Combined: <b>false</b><br>
                   #Columns: <b>1</b><br>
                   Has Column Wrapper(s): <b>false</b><br>
    !]]
    DoxBlockTag(    {"des", "desc", "description"},                             "Description",
                    -_bRequired,    -_bMultipleAllowed),
    --[[!
    @fqxn Dox.Statics.Built-in BlockTags.Note
    @desc Display: <strong>Note</strong><br>
                   Aliases:<br><ul><li>note</li></ul>
                   Required: <b>false</b><br>
                   Multiple Allowed: <b>false</b><br>
                   Combined: <b>false</b><br>
                   #Columns: <b>1</b><br>
                   Has Column Wrapper(s): <b>false</b><br>
    !]]
    DoxBlockTag(    {"note"},                                                   "Note",
                    -_bRequired,    -_bMultipleAllowed),
    --[[!
    @fqxn Dox.Statics.Built-in BlockTags.Summary
    @desc Display: <strong>Summary</strong><br>
                   Aliases:<br><ul><li>summary</li></ul>
                   Required: <b>false</b><br>
                   Multiple Allowed: <b>false</b><br>
                   Combined: <b>false</b><br>
                   #Columns: <b>1</b><br>
                   Has Column Wrapper(s): <b>false</b><br>
    !]]
    DoxBlockTag(    {"summary"},                                                "Summary",
                    -_bRequired,    -_bMultipleAllowed),
    --[[!
    @fqxn Dox.Statics.Built-in BlockTags.Parameter(s)
    @desc Display: <strong>Parameter(s)</strong><br>
                   Aliases:<br><ul><li>parameter</li><li>param</li><li><par/li></ul>
                   Required: <b>false</b><br>
                   Multiple Allowed: <b>true</b><br>
                   Combined: <b>true</b><br>
                   #Columns: <b>3</b><br>
                   Has Column Wrapper(s): <b>true</b><br> (1 & 2)
    !]]
    DoxBlockTag(    {"parameter", "param", "par"},                              "Parameter(s)",
                    -_bRequired,    _bMultipleAllowed,      _bCombined,     2,
                    {"<strong><em>", "</em></strong>"}, {"<em>", "</em>"}),     --TODO move this builder, add functionin blocktag to allow adding/changing
    DoxBlockTag(    {"field"},                                                  "Field(s)",
                    -_bRequired,    _bMultipleAllowed,      _bCombined,     2,
                    {"<strong><em>", "</em></strong>"}, {"<em>", "</em>"}),
    DoxBlockTag(    {"privatefield", "prifield", "prifi"},                      "Field(s) - Private",
                    -_bRequired,    _bMultipleAllowed,      _bCombined,     2,
                    {"<strong><em>", "</em></strong>"}, {"<em>", "</em>"}),
    DoxBlockTag(    {"protectedfield", "profield", "profi"},                    "Field(s) - Protected",
                    -_bRequired,    _bMultipleAllowed,      _bCombined,     2,
                    {"<strong><em>", "</em></strong>"}, {"<em>", "</em>"}),
    DoxBlockTag(    {"publicfield", "pubfield", "pubfi"},                       "Field(s) - Public",
                    -_bRequired,    _bMultipleAllowed,      _bCombined,     2,
    {"<strong><em>", "</em></strong>"}, {"<em>", "</em>"}),
    DoxBlockTag(    {"staticprivatefield", "staprifield", "staprifi"},          "Field(s) - Static Private",
                    -_bRequired,    _bMultipleAllowed,      _bCombined,     2,
                    {"<strong><em>", "</em></strong>"}, {"<em>", "</em>"}),
    DoxBlockTag(    {"staticprotectedfield", "staprofield", "staprofi"},        "Field(s) - Static Protected",
                    -_bRequired,    _bMultipleAllowed,      _bCombined,     2,
                    {"<strong><em>", "</em></strong>"}, {"<em>", "</em>"}),
    DoxBlockTag(    {"staticpublicfield", "stapubfield", "stapubfi"},           "Field(s) - Static Public",
                    -_bRequired,    _bMultipleAllowed,      _bCombined,     2,
                    {"<strong><em>", "</em></strong>"}, {"<em>", "</em>"}),
    DoxBlockTag(    {"prop", "property"},                                       "Property",
                    -_bRequired,    _bMultipleAllowed),
    DoxBlockTag(    {"throws"},                                                 "Throws",
                    -_bRequired,    _bMultipleAllowed),
    DoxBlockTag(    {"return", "ret"},                                          "Return(s)",
                    -_bRequired,    _bMultipleAllowed,     _bCombined,      2,
                    {"<strong><em>", "</em></strong>"}, {"<em>", "</em>"}),
    --NOTE: RESERVED FOR Example Block Tag (inserted during class contruction)
    DoxBlockTag(    {"code"},                                                   "Code",
                    -_bRequired,    _bMultipleAllowed,      -_bCombined,    0,
                    {"<pre>", "</pre>"}),
    DoxBlockTag(    {"requires"},                                               "Requires",
                    -_bRequired,    _bMultipleAllowed,      _bCombined),
    DoxBlockTag(    {"uses"},                                                   "Uses",
                    -_bRequired,    _bMultipleAllowed,      _bCombined),
    DoxBlockTag(    {"features"},                                               "Features",
                    -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag(    {"parent"},                                                 "Parent",
                    -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag(    {"inheritdoc"},                                             "Inheritdoc",
                    -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag(    {"interface"},                                              "Interface",
                    -_bRequired,    _bMultipleAllowed),
    DoxBlockTag(    {"security"},                                               "Security",
                    -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag(    {"performance"},                                            "Performance",
                    -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag(    {"planned"},                                                "Planned Features",
                    -_bRequired,    -_bMultipleAllowed,    _bCombined),
    DoxBlockTag(    {"todo"},                                                   "TODO",
                    -_bRequired,   _bMultipleAllowed,      _bCombined),
    DoxBlockTag(    {"issue"},                                                  "Issue(s)",
                    -_bRequired,   _bMultipleAllowed,      _bCombined),
    DoxBlockTag(    {"bug"},                                                    "Bug(s)",
                    -_bRequired,   _bMultipleAllowed,      _bCombined),
    DoxBlockTag(    {"since"},                                                  "Since",
                    -_bRequired,   -_bMultipleAllowed),
    DoxBlockTag(    {"deprecated"},                                             "Depracated",
                    -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag(    {"changelog", "versionhistory"},                            "Changelog",
                    -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag(    {"version", "ver"},                                         "Version",
                    -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag(    {"see"},                                                    "See",
                    -_bRequired,    _bMultipleAllowed,      _bCombined),
    DoxBlockTag(    {"author"},                                                 "Author(s)",
                    -_bRequired,    _bMultipleAllowed,      _bCombined),
    DoxBlockTag(    {"email"},                                                  "Email",
                    -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag(    {"license"},                                                "License",
                    -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag(    {"www", "web", "website"},                                  "Website",
                    -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag(    {"github"},                                                 "GitHub",
                    -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag(    {"fb", "facebook"},                                         "Facebook",
                    -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag(    {"x", "twitter"},                                           "X (Twitter)",
                    -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag(    {"copy", "copyright"},                                      "Copyright",
                    -_bRequired,    -_bMultipleAllowed),
};
