--[[!
    @fqxn Classes.Utility.Dox.BlockTags
    @desc This is a list of all built-in <a href="#Classes.Utility.Dox.BlockTag">BlockTags</a>.
    <br>While subclasses (parsers) <i>may</i> provide their own, additional BlockTags, these are always guaranteed to be available.
!]]
local _bRequired            = true;
local _bMultipleAllowed     = true;

return {
    --TODO allow modification and ordering --TODO add a bCombine Variable for block tags with (or using) plural form
    --[[!
        @fqxn Classes.Utility.Dox.BlockTags.FQXN
        @desc   Display: FQXN<br>
                Aliases:<br><ul><li>fqxn</li></ul>
                Required: <b>true</b><br>
                Multiple Allowed: <b>false</b><br>
                #Items: <b>1</b>
                <br><br>
                The <b>Fully</b> <b>Q</b>ualified Do<b>x</b> <b>N</b>ame (FQXN) is a required BlockTag that tells Dox how to organize the block in the final html.<br>
                It can be thought of as a unique web address, providing a unique landing page for all items within a block.<br>
                In addition, FQXNs can be used to create anchor links.
        @ex
        --create an anchor link in a comment block to another item.
        --\[\[!
            \@fqxn MyProject.MyClass.MyMethods.Method1
            \@desc This method does neat stuff then calls &lt;a href="MyProject.MyClass.MyMethods.Method2"&gt;Method2&lt;/a&gt;
        !\]\]
    !]]
    DoxBlockTag({"fqxn"},                               "FQXN",                 _bRequired,     -_bMultipleAllowed),
    --[[!
        @fqxn Classes.Utility.Dox.BlockTags.Scope
        @desc Display: Scope<br>
              Aliases:<br><ul><li>scope</li></ul>
              Required: <b>false</b><br>
              Multiple Allowed: <b>false</b><br>
              #Items: <b>1</b>
    !]]
    DoxBlockTag({"scope"},                              "Scope",                -_bRequired,    -_bMultipleAllowed,   0,  {"<em>", "</em>"}),
    --[[!
        @fqxn Classes.Utility.Dox.BlockTags.Visibility
        @desc Display: Visibility<br>
                       Aliases:<br><ul><li>vis</li>visi<li>visibility</li></ul>
                       Required: <b>false</b><br>
                       Multiple Allowed: <b>false</b><br>
                       #Items: <b>1</b>
    !]]
    DoxBlockTag({"vis", "visi", "visibility"},          "Visibility",           -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag({"des", "desc", "description"},         "Description",          -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag({"note"},                               "Note",                 -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag({"summary"},                            "Summary",              -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag({"parameter", "param", "par"},          "Parameter",            -_bRequired,    _bMultipleAllowed,    2,  {"<strong><em>", "</em></strong>"}, {"<em>", "</em>"}),--TODO move this builder, add functionin blocktag to allow adding/changing 
    DoxBlockTag({"field"},                              "Field",                -_bRequired,    _bMultipleAllowed),
    DoxBlockTag({"prop", "property"},                   "Property",             -_bRequired,    _bMultipleAllowed),
    DoxBlockTag({"throws"},                             "Throws",               -_bRequired,    _bMultipleAllowed),
    DoxBlockTag({"return", "ret"},                      "Return",               -_bRequired,    _bMultipleAllowed,    2,  {"<strong><em>", "</em></strong>"}, {"<em>", "</em>"}),
    --NOTE: RESERVED FOR Example Block Tag (inserted during class contruction)
    DoxBlockTag({"code"},                               "Code",                 -_bRequired,    _bMultipleAllowed,    0,  {"<pre>", "</pre>"}),
    DoxBlockTag({"requires"},                           "Requires",             -_bRequired,    _bMultipleAllowed),
    DoxBlockTag({"uses"},                               "Uses",                 -_bRequired,    _bMultipleAllowed),
    DoxBlockTag({"features"},                           "Features",             -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag({"parent"},                             "Parent",               -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag({"interface"},                          "Interface",            -_bRequired,    _bMultipleAllowed),
    DoxBlockTag({"security"},                           "Security",             -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag({"performance"},                        "Performance",          -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag({"planned"},                            "Planned Features",     -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag({"todo"},                               "TODO",                 -_bRequired,    _bMultipleAllowed),
    DoxBlockTag({"issue"},                              "Issue",                -_bRequired,    _bMultipleAllowed),
    DoxBlockTag({"bug"},                                "Bug",                  -_bRequired,    _bMultipleAllowed),
    DoxBlockTag({"since"},                              "Since",                -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag({"deprecated"},                         "Depracated",           -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag({"changelog", "versionhistory"},        "Changelog",            -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag({"version", "ver"},                     "Version",              -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag({"see"},                                "See",                  -_bRequired,    _bMultipleAllowed),
    DoxBlockTag({"author"},                             "Author",               -_bRequired,    _bMultipleAllowed),
    DoxBlockTag({"email"},                              "Email",                -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag({"license"},                            "License",              -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag({"www", "web", "website"},              "Website",              -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag({"github"},                             "GitHub",               -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag({"fb", "facebook"},                     "Facebook",             -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag({"x", "twitter"},                       "X (Twitter)",          -_bRequired,    -_bMultipleAllowed),
    DoxBlockTag({"copy", "copyright"},                  "Copyright",            -_bRequired,    -_bMultipleAllowed),
};
