const documentationData = {
    "ModuleA": {
        value: "Some value for ModuleA",
        subtable: {
            "Functions": {
                value: "Some value for Functions in ModuleA",
                subtable: {
                    "FunctionA1": {
                        value: "Details about FunctionA1.",
                        subtable: null
                    },
                    "FunctionA2": {
                        value: "Details about FunctionA2.",
                        subtable: null
                    },
                    "FunctionA3": {
                        value: "Details about FunctionA3.",
                        subtable: null
                    }
                }
            },
            "Enums": {
                value: "Some value for Enums in ModuleA",
                subtable: {
                    "EnumA1": {
                        value: "Details about EnumA1.",
                        subtable: null
                    },
                    "EnumA2": {
                        value: "Details about EnumA2.",
                        subtable: null
                    }
                }
            },
            "Constants": {
                value: "Some value for Constants in ModuleA",
                subtable: {
                    "ConstantA1": {
                        value: "Details about ConstantA1.",
                        subtable: null
                    }
                }
            },
            "SubModuleA1": {
                value: "Some value for SubModuleA1",
                subtable: {
                    "Functions": {
                        value: "Some value for Functions in SubModuleA1",
                        subtable: {
                            "FunctionA1.1": {
                                value: "Details about FunctionA1.1.",
                                subtable: null
                            },
                            "FunctionA1.2": {
                                value: "Details about FunctionA1.2.",
                                subtable: null
                            }
                        }
                    },
                    "SubModuleA1.1": {
                        value: "Some value for SubModuleA1.1",
                        subtable: {
                            "Functions": {
                                value: "Some value for Functions in SubModuleA1.1",
                                subtable: {
                                    "FunctionA1.1.1": {
                                        value: "Details about FunctionA1.1.1.",
                                        subtable: null
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    },
    "ModuleB": {
        value: "Some value for ModuleB",
        subtable: {
            "Functions": {
                value: "Some value for Functions in ModuleB",
                subtable: {
                    "FunctionB1": {
                        value: "Details about FunctionB1.",
                        subtable: null
                    },
                    "FunctionB2": {
                        value: "Details about FunctionB2.",
                        subtable: null
                    }
                }
            },
            "Enums": {
				value: "Some value for Enums in ModuleB",
				subtable: {
					"EnumB1": {
						value: "Details about EnumB1.",
						subtable: null
					},
					"EnumB2": {
						value: "Details about EnumB2.",
						subtable: {
							"EnumB2_1": {
								value: "Details about EnumB2_1.",
								subtable: null
							},
							"EnumB2_2": {
								value: "Details about EnumB2_2.",
								subtable: {
									"EnumB2_2_1": {
										value: "Details about EnumB2_2_1.",
										subtable: null
									},
									"EnumB2_2_2": {
										value: "Details about EnumB2_2_2.",
										subtable: null
									}
								}
							}
						}
					},
					"EnumB3": {
						value: "Details about EnumB3.",
						subtable: {
							"Stuff1": {
								value: "Details about stugg1",
								subtable: null
							},
							"Stuff2": {
								value: "Details about stugg2",
								subtable: null
							},
						},
					},
					"EnumB4": {
						value: "Details about EnumB4.",
						subtable: null
					}
				}
			},
            "Constants": {
                value: "Some value for Constants in ModuleB",
                subtable: {
                    "ConstantB1": {
                        value: "Details about ConstantB1.",
                        subtable: null
                    },
                    "ConstantB2": {
                        value: "Details about ConstantB2.",
                        subtable: null
                    }
                }
            },
            "SubModuleB1": {
                value: "Some value for SubModuleB1",
                subtable: {
                    "Functions": {
                        value: "Some value for Functions in SubModuleB1",
                        subtable: {
                            "FunctionB1.1": {
                                value: "Details about FunctionB1.1.",
                                subtable: null
                            }
                        }
                    },
                    "SubModuleB1.1": {
                        value: "Some value for SubModuleB1.1",
                        subtable: {
                            "Functions": {
                                value: "Some value for Functions in SubModuleB1.1",
                                subtable: {
                                    "FunctionB1.1.1": {
                                        value: "Details about FunctionB1.1.1.",
                                        subtable: null
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    },
    "ModuleC": {
        value: "Some value for ModuleC",
        subtable: {
            "Functions": {
                value: "Some value for Functions in ModuleC",
                subtable: {
                    "FunctionC1": {
                        value: "Details about FunctionC1.",
                        subtable: null
                    }
                }
            },
            "SubModuleC1": {
                value: "Some value for SubModuleC1",
                subtable: {
                    "Functions": {
                        value: "Some value for Functions in SubModuleC1",
                        subtable: {
                            "FunctionC1.1": {
                                value: "Details about FunctionC1.1.",
                                subtable: null
                            },
                            "FunctionC1.2": {
                                value: "Details about FunctionC1.2.",
                                subtable: null
                            }
                        }
                    },
                    "SubModuleC1.1": {
                        value: "Some value for SubModuleC1.1",
                        subtable: {
                            "Functions": {
                                value: "Some value for Functions in SubModuleC1.1",
                                subtable: {
                                    "FunctionC1.1.1": {
                                        value: "Details about FunctionC1.1.1.",
                                        subtable: null
                                    },
                                    "FunctionC1.1.2": {
                                        value: "Details about FunctionC1.1.2.",
                                        subtable: null
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
};


// Global variable to store the current path
let currentPath = '';


// Load top-level modules into the sidebar
function loadSidebar() {
    const menu = document.getElementById('menu1');
    menu.innerHTML = '';
    for (const module in documentationData) {
        const li = document.createElement('li');
        li.className = 'nav-item';
        const a = document.createElement('a');
        a.href = '#';
        a.className = 'nav-link';
        a.textContent = module;
        a.onclick = function() {
            currentPath = module; // Update the current path
            updateBreadcrumb();
            loadSidebar2(documentationData[module].subtable); // Load the second sidebar
			const newValue = getPropertyByPath(documentationData, currentPath, "value");
                if (newValue) {                    
                        content.innerHTML = newValue;
                }
        };
        li.appendChild(a);
        menu.appendChild(li);
    }
}



function getPropertyByPath(obj, path, property) {
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

function updateBreadcrumb() {
    const breadcrumb = document.getElementById('breadcrumb');
    const content = document.getElementById('content');
    const parts = currentPath.split('.');
    let currentData = documentationData;
    breadcrumb.innerHTML = '';

    parts.forEach((part, index) => {
        let li = document.createElement('li');
        li.className = 'breadcrumb-item';

        if (index === parts.length - 1) {
            li.textContent = part;
            li.className += ' active';
            li.setAttribute('aria-current', 'page');
        } else {
            let a = document.createElement('a');
            a.href = '#';
            a.textContent = part;
            a.onclick = function() {
                currentPath = parts.slice(0, index + 1).join('.');
                updateBreadcrumb();
                const newData = getPropertyByPath(documentationData, currentPath, "subtable");
				const newValue = getPropertyByPath(documentationData, currentPath, "value");
                if (newData) {
                    loadSidebar2(newData);                    
                }
				if (newValue) {
					content.innerHTML = newValue;
				}
            };
            li.appendChild(a);
        }

        breadcrumb.appendChild(li);

        if (currentData && currentData[part]) {
            currentData = currentData[part].subtable || currentData[part];
        }
    });

    //if (currentData && typeof currentData.value === 'string') {
    //    content.innerHTML = currentData.value;
   // } else {
     //   content.innerHTML = 'Select a subitem to see details.';
   // }
}


function loadSidebar2(data) {
    const menu2 = document.getElementById('menu2');
    menu2.innerHTML = '';

    Object.keys(data).forEach(key => {
        const li = document.createElement('li');
        li.className = 'nav-item';
        const a = document.createElement('a');
        a.className = 'nav-link';
        a.href = '#';
        a.textContent = key;
        a.onclick = function() {
            currentPath += `.${key}`;
            updateBreadcrumb();
            const subtable = data[key].subtable;
            if (subtable) {
                loadSidebar2(subtable);
            } else {
                menu2.innerHTML = ''; // Clear menu2 if there's no subtable
            }
            if (data[key].value) {
                document.getElementById('content').innerHTML = data[key].value;
            }
			document.getElementById('menu2itemtitle').innerHTML = "test";
        };
        li.appendChild(a);
        menu2.appendChild(li);
    });
}



// Initial load
loadSidebar();
updateBreadcrumb('Home');
