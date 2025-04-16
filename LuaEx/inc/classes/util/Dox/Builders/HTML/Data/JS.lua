--[[!
@fqxn Dox.Builders.HTML.Data.JS
@des The core Javascript code that is used when creating the final HTML document.
!]]
return [[
const userData = {
    "ModuleA": {
        "value": "Some value for ModuleA",
        "subtable": {
            "Functions": {
                "value": "Some value for Functions in ModuleA",
                "subtable": {
                    "FunctionA1": {
                        "value": "Details about FunctionA1.",
                        "subtable": null
                    },
                    "FunctionA2": {
                        "value": "Details about FunctionA2.",
                        "subtable": null
                    },
                    "FunctionA3": {
                        "value": "Details about FunctionA3.",
                        "subtable": null
                    }
                }
            },
            "Enums": {
                "value": "Some value for Enums in ModuleA",
                "subtable": {
                    "EnumA1": {
                        "value": "Details about EnumA1.",
                        "subtable": null
                    },
                    "EnumA2": {
                        "value": "Details about EnumA2.",
                        "subtable": null
                    }
                }
            },
            "Constants": {
                "value": "Some value for Constants in ModuleA",
                "subtable": {
                    "ConstantA1": {
                        "value": "Details about ConstantA1.",
                        "subtable": null
                    }
                }
            }
        }
    },
    "ModuleB": {
        "value": "Some value for ModuleA",
        "subtable": {
            "Functions": {
                "value": "Some value for Functions in ModuleA",
                "subtable": {
                    "FunctionA1": {
                        "value": "Details about FunctionA1.",
                        "subtable": null
                    },
                    "FunctionA2": {
                        "value": "Details about FunctionA2.",
                        "subtable": null
                    },
                    "FunctionA3": {
                        "value": "Details about FunctionA3.",
                        "subtable": null
                    }
                }
            },
            "Enums": {
                "value": "Some value for Enums in ModuleA",
                "subtable": {
                    "EnumA1": {
                        "value": "Details about EnumA1.",
                        "subtable": null
                    },
                    "EnumA2": {
                        "value": "Details about EnumA2.",
                        "subtable": null
                    }
                }
            },
            "Constants": {
                "value": "Some value for Constants in ModuleA",
                "subtable": {
                    "ConstantA1": {
                        "value": "Details about ConstantA1.",
                        "subtable": null
                    }
                }
            }
        }
    }
};
//—©_END_DOX_TESTDATA_©—
const doxData = {
    "Modules": {
        "value": `
        <div class="DOX_intro container">
            <div class="row">
                <div class="col-lg-12">
                    <div class="p-5 text-center rounded">
                        <h1 class="DOX_intro">Welcome to Dox: The Lua-based Documentation System!</h1>
                        <p class="DOX_intro lead">With Dox, you can effortlessly organize and navigate through your project's documentation, making it easier for your team and users to find the information they need.</p>
                        <p class="DOX_intro lead">Explore its features to see how Dox can streamline your documentation process and enhance collaboration:</p>
                        <ul class="list-unstyled">
                            <li><i class="DOX_intro fas fa-angle-double-right"></i> Simple to Use</li>
                            <li><i class="DOX_intro fas fa-angle-double-right"></i> Easy Sidebar Navigation</li>
                            <li><i class="DOX_intro fas fa-angle-double-right"></i> Breadcrumb Navigation</li>
                            <li><i class="DOX_intro fas fa-angle-double-right"></i> Dynamic Content Updates</li>
                            <li><i class="DOX_intro fas fa-angle-double-right"></i> Customizable Styling</li>
                            <li><i class="DOX_intro fas fa-angle-double-right"></i> Responsive Design for Any Device</li>
                            <li><i class="DOX_intro fas fa-angle-double-right"></i> Document Any Language <em>(Even A Custom One)</em></li>
                            <li><i class="DOX_intro fas fa-angle-double-right"></i> Uses <a href="https://prismjs.com/" target="_blank">Prism</a> For Beautiful Code Examples</li>
                            <li><i class="DOX_intro fas fa-angle-double-right"></i> Free Forever, Public Domain Code</li>
                        </ul>
                        <br>
                        <strong>Download LuaEx <em>(containing Dox)</em></strong>
                        <br>
                        <a class="DOX_intro" href="https://github.com/CentauriSoldier/LuaEx" target="_blank">https://github.com/CentauriSoldier/LuaEx</a>
                    </div>
                </div>
            </div>
        </div>
        `,
        "subtable": userData
    }
};
//—©_END_DOX_DEFAULT_INTRO_©—

class Dox {


    constructor() {
        if (!Dox.instance) {
            Dox.instance = this;
            this.data = doxData;
            this.activeFQXN = "Modules";
            this.previousFQXN = "";
            // Initialize link click event listener (for handling anchor links)
            /*document.body.addEventListener('click', (event) => {
                const target = event.target;

                if (target && target.tagName === 'A') {
                    // Check if the target has an href property and starts with the specified protocols
                    if (target.href && (
                        target.href.startsWith('file:///') ||
                        target.href.startsWith('http://')  ||
                        target.href.startsWith('https://') ||
                        target.href.startsWith('www')
                    )) {
                        event.preventDefault(); // Prevent default link behavior
                        const anchorIndex = target.href.indexOf('#');
                        const strippedString = target.href.substring(anchorIndex + 1).trim(); // Trim any leading/trailing whitespace

                        if (strippedString !== '') {
                            const sFQXN = "Modules." + strippedString;

                            if (this.setActiveFQXN(sFQXN)) {
                                this.updatePage();
                            }
                        }
                    }
                }
            });*/
            /*document.body.addEventListener('click', (event) => {
                const target = event.target;

                if (target && target.tagName === 'A') {
                    const anchorIndex = target.href.indexOf('#');

                    if (anchorIndex !== -1) { // It's an internal link
                        event.preventDefault(); // Prevent default link behavior
                        const strippedString = target.href.substring(anchorIndex + 1).trim(); // Trim any leading/trailing whitespace

                        if (strippedString !== '') {
                            const sFQXN = "Modules." + strippedString;

                            if (this.setActiveFQXN(sFQXN)) {
                                this.updatePage();
                            }
                        }
                    }
                }
            });*/
            document.body.addEventListener('click', (event) => {
                const target = event.target;

                if (target && target.tagName === 'A') {
                    // Replace spaces with %20 in the href attribute
                    //const updatedHref = target.href.replace(/ /g, '%20');
                    const updatedHref = target.href.replace(' ', '%20');
                    const anchorIndex = updatedHref.indexOf('#');

                    if (anchorIndex !== -1) { // It's an internal link
                        event.preventDefault(); // Prevent default link behavior
                        const strippedString = updatedHref.substring(anchorIndex + 1).trim(); // Trim any leading/trailing whitespace

                        if (strippedString !== '') {
                            const sFQXN = "Modules." + strippedString;

                            if (this.setActiveFQXN(sFQXN)) {
                                this.updatePage();
                            }
                        }
                    }
                }
            });

            /* Test for navigating to link in address bar 
            window.addEventListener('load', function() {
              if (window.location.hash) {
                // Strip off the '#' and possibly prefix the key if needed
                const strippedString = window.location.hash.substring(1).trim();
                // Assuming your internal keys are prefixed by "Modules."
                const sFQXN = "Modules." + strippedString;
                if (doxInstance.setActiveFQXN(sFQXN)) {
                  doxInstance.updatePage();
                }
              }
            });*/

            // Listen for the popstate event
            window.addEventListener('popstate', () => {
                // When the user navigates back or forward, retrieve the stored FQXN from the history state
                const fqxn = history.state && history.state.activeFQXN;
                if (fqxn && this.setActiveFQXN(fqxn)) {
                    // Update your application with the retrieved FQXN
                    this.updatePage();
                }
            });
        }
        return Dox.instance;
    }


    byID(sID) {
        return document.getElementById(sID);
    }

    getPropertyByPath(obj, path, property) {
        const parts = path.split('.');
        let current = obj;

        for (let part of parts) {
            if (current[part]) {
                //current = current[part].subtable !== null ? current[part].subtable : current[part];
                current = current[part][property] !== null ? current[part][property] : current[part];
            } else {
                return undefined;
            }
        }
        return current;
    }


    fqxnIsValid(sFQXN) {
        let tRet = false;
        let tCurrent = this.data;

        if (sFQXN) {
            const tParts = sFQXN.split('.');

            for (const sPart of tParts) {

                if (tCurrent[sPart]) {
                    tRet = true;
                    tCurrent = tCurrent[sPart];

                    if (tCurrent.subtable) {
                        tCurrent = tCurrent.subtable;
                    }
                } else {
                    return false;
                }
            }
        }

        return tRet;
    }


    getDataByFQDN(fqxn) {
        let tRet = null;
        let tCurrent = this.data;

        if (fqxn) {
            const tParts = fqxn.split('.');

            for (const sPart of tParts) {

                if (tCurrent[sPart]) {
                    tRet = tCurrent[sPart];
                    tCurrent = tCurrent[sPart];

                    if (tCurrent.subtable) {
                        tCurrent = tCurrent.subtable;
                    }
                } else {
                    return null;
                }
            }
        }

        return tRet;
    }


    getActiveFQXN() {
        return this.activeFQXN;
    }


    setActiveFQXN(sFQXN) {
        let bRet = this.fqxnIsValid(sFQXN);

        if (bRet) {
            this.activeFQXN = sFQXN;
        }

        return bRet;
    }


    updateContent() {
        const sActiveFQXN   = this.getActiveFQXN();
        const tData         = this.getDataByFQDN(sActiveFQXN);

        if (tData) {
            const value     = tData["value"];
            const content   = this.byID('DOX_content'); //TODO rename these to avoid user id collision
            content.innerHTML  = '';

            if (value) {
                content.innerHTML = value;
            } else {
                content.innerHTML = '';
            }

        }

    }

    updateBreadcrumb() {
        const breadcrumb = this.byID('DOX_breadcrumb');
        breadcrumb.innerHTML = ''; // Clear previous breadcrumb items

        const tParts = this.getActiveFQXN().split('.'); // Split the activeFQXN into parts

        tParts.forEach((part, nIndex) => {
            const li = document.createElement('li');
            li.className = 'breadcrumb-item';

            if (nIndex === tParts.length - 1) {
                li.textContent = part.replace("%20", " ");
                li.className += ' active';
                li.setAttribute('aria-current', 'page');
            } else {
                const a = document.createElement('a');
                a.href = '#';
                a.textContent = part.replace("%20", " ");
                a.onclick = () => {
                    const newPath = tParts.slice(0, nIndex + 1).join('.');
                    if (this.fqxnIsValid(newPath)) {
                        this.setActiveFQXN(newPath);
                        this.updatePage();
                    }
                };
                li.appendChild(a);
            }

            breadcrumb.appendChild(li);
        });
    }


    updateNavMenu() {
        const sActiveFQXN = this.getActiveFQXN();
        const tData = this.getDataByFQDN(sActiveFQXN);

        if (tData) {
            const menu = this.byID('DOX_navmenu');
            menu.innerHTML = ''; // Clear the current HTML from the menu

            if (tData.subtable) {
                const subtable = tData.subtable;

                // Create the list items for subtable items
                Object.keys(subtable).forEach(key => {
                    const li = document.createElement('li');
                    li.className = 'nav-item';

                    const a = document.createElement('a');
                    a.href = '#';
                    a.className = 'nav-link';
                    a.textContent = key.replace("%20", " ");

                    const sTestFQXN = `${this.getActiveFQXN()}.${key}`;

                    if (this.fqxnIsValid(sTestFQXN)) {
                        a.onclick = () => {
                            let newData = this.getDataByFQDN(sTestFQXN);
                            if (!newData) {
                                a.removeAttribute('href');
                                a.classList.add('disabledlink');
                            } else {
                                this.setActiveFQXN(sTestFQXN);
                                this.updatePage();
                            }
                        };
                    }

                    li.appendChild(a);
                    menu.appendChild(li);
                });
            } else {
                // Load menu with elements from the table above it
                const parentData = this.getDataByFQDN(sActiveFQXN.split('.').slice(0, -1).join('.'));
                if (parentData && parentData.subtable) {
                    Object.keys(parentData.subtable).forEach(key => {
                        const li = document.createElement('li');
                        li.className = 'nav-item';

                        const a = document.createElement('a');
                        a.href = '#';
                        a.className = 'nav-link';
                        a.textContent = key.replace("%20", " ");

                        const sTestFQXN = `${sActiveFQXN.split('.').slice(0, -1).join('.')}.${key}`;

                        if (this.fqxnIsValid(sTestFQXN)) {
                            a.onclick = () => {
                                this.setActiveFQXN(sTestFQXN);
                                this.updatePage();
                            };
                        }

                        li.appendChild(a);
                        menu.appendChild(li);
                    });
                }
            }
        }
    }


    updatePage() {
        this.updateNavMenu();
        this.updateBreadcrumb();
        this.updateContent();
        Prism.highlightAll();
        history.pushState({ activeFQXN: this.getActiveFQXN() }, '');
    }


    static copyToClipboard(button) {
        // Get the parent element's id
        var parentId = button.parentElement.id;

        // Select the section content div that is a sibling of the section-title div
        var sectionContent = button.parentElement.nextElementSibling;

        // Find the code block inside the section-content div
        var codeBlock = sectionContent.querySelector('pre code').innerText;

        // Create a temporary textarea element to copy the text
        var textarea = document.createElement('textarea');
        textarea.value = codeBlock;
        document.body.appendChild(textarea);
        textarea.select();
        document.execCommand('copy');
        document.body.removeChild(textarea);

        // Optionally, show an alert or some feedback
        // alert('Code copied to clipboard!');
    }

}
]];
