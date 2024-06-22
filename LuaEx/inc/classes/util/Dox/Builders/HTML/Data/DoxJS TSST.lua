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
        <div class="container">
            <div class="row">
                <div class="col-lg-12">
                    <div class="welcome-message p-5 text-center bg-light rounded">
                        <h1 class="text-primary">Welcome to Dox: The Lua-based Documentation System!</h1>
                        <p class="lead">With Dox, you can effortlessly organize and navigate through your project's documentation, making it easier for your team and users to find the information they need.</p>
                        <p class="lead">Explore its features to see how Dox can streamline your documentation process and enhance collaboration:</p>
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
            this.previousFQXN = "Modules";
            this.nextFQXN = "Modules"; // Gets set on back button

            // Initialize link click event listener
            document.body.addEventListener('click', (event) => {
                const target = event.target;
                if (target.tagName === 'A' && target.href.startsWith('file:///')) {
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
            });

            // Listen for the popstate event
            window.addEventListener('popstate', (event) => {
                const currentState = event.state.activeFQXN;
                const previousState = this.previousFQXN; // Function to get the previous state
                console.log(currentState, previousState)
                if (previousState && currentState) {
                    if (currentState === previousState.previousFQXN) {
                        // It's a "back" navigation
                        // Handle back navigation logic here
                        this.setActiveFQXN(previousState.previousFQXN);
                    } else if (currentState === previousState.nextFQXN) {
                        // It's a "forward" navigation
                        // Handle forward navigation logic here
                        this.setActiveFQXN(previousState.nextFQXN);
                    }

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
            history.pushState({ previousFQXN: this.activeFQXN }, ''); // Update history state
            this.activeFQXN = sFQXN;
        }
        return bRet;
    }

    updateContent() {
        const sActiveFQXN   = this.getActiveFQXN();
        const tData         = this.getDataByFQDN(sActiveFQXN);

        if (tData) {
            const value     = tData["value"];
            const content   = this.byID('DOX_content');
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
        breadcrumb.innerHTML = '';

        const tParts = this.getActiveFQXN().split('.');

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
        const sActiveFQXN = this.getActiveFQXN();
        const tData = this.getDataByFQDN(sActiveFQXN);

        if (tData) {
            const menu = this.byID('DOX_navmenu');
            menu.innerHTML = '';

            if (tData.subtable) {
                const subtable = tData.subtable;

                Object.keys(subtable).forEach(key => {
                    const li = document.createElement('li');
                    li.className = 'nav-item';

                    const a = document.createElement('a');
                    a.href = '#';
                    a.className = 'nav-link';
                    a.textContent = key;

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
                const parentData = this.getDataByFQDN(sActiveFQXN.split('.').slice(0, -1).join('.'));
                if (parentData && parentData.subtable) {
                    Object.keys(parentData.subtable).forEach(key => {
                        const li = document.createElement('li');
                        li.className = 'nav-item';

                        const a = document.createElement('a');
                        a.href = '#';
                        a.className = 'nav-link';
                        a.textContent = key;

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
    }
}


]];
