return [[
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${__DOX__TITLE__} Documentation</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
    ${__DOX__PRISM_CSS__}

    <style>
        ${__DOX__CSS__}

        .sidebar {
            height: 100vh;
            overflow-y: auto;
        }

        #DOX_content {
            height: calc(100vh - 56px); /* Adjust this value if the breadcrumb bar height changes */
            overflow-y: auto;
        }

        /* Optional: Ensure the breadcrumb bar stays at the top */
        .breadcrumb-wrapper {
            position: sticky;
            top: 0;
            z-index: 1000;
        }
    </style>
</head>
<body>
    <div class="container-fluid">
        <div class="row">
            <div class="col-12 m-0 p-0">
                <div id="banner" class="container-fluid">
                    <div id="titlebg" class="d-flex align-items-center">
                        <div class="flex-grow-1 text-center">
                            <h1 id="title">${__DOX__TITLE__} Documentation</h1>
                            <p class="fst-italic">Auto Generated by <a class="fst-italic" href="https://github.com/CentauriSoldier/LuaEx" target="_blank">LuaEx's Dox Module</a></p>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Breadcrumb bar -->
        <div class="row bg-secondary">
            <nav aria-label="breadcrumb">
                <ol class="breadcrumb breadcrumb-wrapper" id="DOX_breadcrumb"></ol>
            </nav>
        </div>

        <div class="row">
            <!-- Sidebar Wrapper - Column 1 -->
            <div class="col-3 bg-secondary text-light sidebar">
                <ul id="DOX_navmenu" class="nav flex-column"></ul>
            </div>

            <!-- Main Panel - Column 3 -->
            <div class="col-9 bg-light p-0 m-0">

                <!-- Content -->
                <!-- <div id="DOX_content" class="scrollable-div overflow-auto border"></div>-->
                <div id="DOX_content"></div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js" integrity="sha384-YvpcrYf0tY3lHB60NNkmXc5s9fDVZLESaAA55NDzOxhy9GkcIdslK1eN7N6jIeHz" crossorigin="anonymous"></script>
    ${__DOX__PRISM__SCRIPTS__}

    <!-- Instantiate Dox and update the page -->
    <script>
        ${__DOX__INTERNAL_JS__}
        const oDox = new Dox();
        oDox.updatePage();
    </script>
</body>
</html>
]];