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
        <div class="container">
            <div class="row">
                <div class="col-lg-12">
                    <div class="welcome-message p-5 text-center bg-light rounded">
                        <h1 class="text-primary">Welcome to Dox: The Lua-based Documentation System!</h1>
                        <p class="lead">We're thrilled to introduce you to our new documentation system, Dox. With Dox, you can effortlessly organize and navigate through your project's documentation, making it easier for your team and users to find the information they need.</p>
                        <p class="lead">Explore our features to see how Dox can streamline your documentation process and enhance collaboration:</p>
                        <ul class="list-unstyled">
                            <li><i class="fas fa-angle-double-right text-primary"></i> Simple to Use</li>
                            <li><i class="fas fa-angle-double-right text-primary"></i> Efficient Sidebar Navigation</li>
                            <li><i class="fas fa-angle-double-right text-primary"></i> Dynamic Content Updates</li>
                            <li><i class="fas fa-angle-double-right text-primary"></i> Customizable Styling</li>
                            <li><i class="fas fa-angle-double-right text-primary"></i> Responsive Design for Any Device</li>
                            <li><i class="fas fa-angle-double-right text-primary"></i> Document Any <em>(Even A Custom)</em> Language</li>
                            <li><i class="fas fa-angle-double-right text-primary"></i> Free forever, Public Domain Code</li>
                        </ul>
                        <br>
                        <strong>Download LuaEx <em>(containing Dox)</em></strong>
                        <br>
                        <a href="https://github.com/CentauriSoldier/LuaEx" target="_blank">https://github.com/CentauriSoldier/LuaEx</a>
                    </div>
                </div>
            </div>
        </div>
        `,
        "subtable": userData
    }
};


class Dox {


    constructor() {
        if (!Dox.instance) {
            Dox.instance = this;
            this.data = doxData;
            this.activeFQXN = "Modules";
            this.previousFQXN = "";
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
                li.textContent = part;
                li.className += ' active';
                li.setAttribute('aria-current', 'page');
            } else {
                const a = document.createElement('a');
                a.href = '#';
                a.textContent = part;
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
        const sActiveFQXN   = this.getActiveFQXN();
        const tData         = this.getDataByFQDN(sActiveFQXN);

        if (tData) {
            const subtable = tData["subtable"];

            // Add subtable items to the menu
            if (subtable) {
                const menu = this.byID('DOX_navmenu');
                const sValue = tData["value"];

                // Clear the current HTML from the menu
                menu.innerHTML = '';

                // Create the list items
                Object.keys(subtable).forEach(key => {

                    // Create a new list item for each key in subtable
                    const li = document.createElement('li');
                    li.className = 'nav-item';

                    // Create the link for the current table
                    const a = document.createElement('a');
                    a.href = '#';
                    a.className = 'nav-link';
                    a.textContent = key;

                    const sTestFQXN = `${this.getActiveFQXN()}.${key}`;

                    if (this.fqxnIsValid(sTestFQXN)) {
                        a.onclick = function() {
                            // See if there's a subtable
                            let newData = this.getDataByFQDN(sTestFQXN);
                            if (!newData) {
                                // Remove the href attribute and disable the link
                                a.removeAttribute('href');
                                a.classList.add('disabledlink');
                            } else {
                                this.setActiveFQXN(sTestFQXN);
                                this.updatePage();
                            }
                        }.bind(this);
                    }

                    // Append the link to the list item
                    li.appendChild(a);

                    // Append the list item to the menu
                    menu.appendChild(li);

                });
            }
        }
    }


    updatePage() {
        this.updateNavMenu();
        this.updateBreadcrumb();
        this.updateContent();
    }


}
