return [[
    :root {
            --base-font-size: 16px; /* Define a base font size */

            /* Color Scheme */
            --title-heading: #93B3A3;
            --navbackground: #3F3F3F;
            --navlink: #F0DFAF;
            --navlinkhover: #7F9F7F;
            --sectiontitle: #2E4340;
            --sectiontitlebg: #CCDC90;
            --sectioncontent: #DCDCCC;
    }

    /*Section for setting viewport sizes
     ██████╗ ███╗   ███╗███████╗██████╗ ██╗ █████╗
    ██╔═══██╗████╗ ████║██╔════╝██╔══██╗██║██╔══██╗
    ██║██╗██║██╔████╔██║█████╗  ██║  ██║██║███████║
    ██║██║██║██║╚██╔╝██║██╔══╝  ██║  ██║██║██╔══██║
    ╚█║████╔╝██║ ╚═╝ ██║███████╗██████╔╝██║██║  ██║
     ╚╝╚═══╝ ╚═╝     ╚═╝╚══════╝╚═════╝ ╚═╝╚═╝  ╚═╝*/
    @media (min-width: 0px) {
        html { font-size: 10px; }
        #DOX_navmenu .nav-link { font-size: 12px; }
    }
    @media (min-width: 300px) {
        html { font-size: 12px; }
        #DOX_navmenu .nav-link { font-size: 13px; }

    }
    @media (min-width: 576px) {
        html { font-size: 13px; }
        #DOX_navmenu .nav-link { font-size: 14px; }

    }
    @media (min-width: 768px) {
        html { font-size: 14px; }
        #DOX_navmenu .nav-link { font-size: 15px; }

    }
    @media (min-width: 992px) {
        html { font-size: 15px; }
        #DOX_navmenu .nav-link { font-size: 16px; }

    }
    @media (min-width: 1200px) {
        html { font-size: 16px; }
        #DOX_navmenu .nav-link { font-size: 18px; }
    }


    /* General styles for the DOX_intro container
    ██╗███╗   ██╗████████╗██████╗  ██████╗
    ██║████╗  ██║╚══██╔══╝██╔══██╗██╔═══██╗
    ██║██╔██╗ ██║   ██║   ██████╔╝██║   ██║
    ██║██║╚██╗██║   ██║   ██╔══██╗██║   ██║
    ██║██║ ╚████║   ██║   ██║  ██║╚██████╔╝
    ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝ */
    .DOX_intro {
        color: var(--sectioncontent); /* Text color for all text within the container */
        background-color: var(--navbackground); /* Background color for the container */
    }

    .DOX_intro p {
        color: #7F9F7F; /* Specific text color for paragraphs */
        font-weight: bold;
    }

    .DOX_intro h1, .DOX_intro strong {
        color: #8CD0D3 !important; /* Ensure this color is applied */
    }

    .DOX_intro a {
        color: #EFEF8F; /* Specific text color for links */
        background-color: var(--linkbackground); /* Background color for links if needed */
    }

    .DOX_intro * {
        background-color: inherit; /* Inherit background color from the container */
        color: inherit; /* Inherit text color from the container */
    }

    /*
    ████████╗██╗████████╗██╗     ███████╗
    ╚══██╔══╝██║╚══██╔══╝██║     ██╔════╝
       ██║   ██║   ██║   ██║     █████╗
       ██║   ██║   ██║   ██║     ██╔══╝
       ██║   ██║   ██║   ███████╗███████╗
       ╚═╝   ╚═╝   ╚═╝   ╚══════╝╚══════╝*/
    #title {
        font-family: 'Arial', sans-serif; /* Specify your preferred font-family */
        font-size: 2.5rem; /* Adjust font size as needed */
        font-weight: bold; /* Make the text bold */
        color: var(--title-heading); /* Use Zenburn color for the title text */
        text-align: center; /* Center-align the text */
        margin-bottom: 3px; /* Add some bottom margin for spacing */
    }

    #titlebg {
        background: linear-gradient(180deg,
            #0F0F0F, /* Even darker gray */
            var(--navbackground)
        );
        color: #F0E8C0; /* Light color for text to ensure readability */
        padding: 4px; /* Optional padding for better spacing */
    }

    p.title.fst-italic {
        margin: 0; /* Remove margin from paragraphs with both 'title' and 'fst-italic' classes */
    }

    p.title.fst-italic {
        color: var(--sectioncontent);
    }

    a.title.fst-italic {
        color: var(--navlink);
        text-decoration: underline; /* Optional: adds underline to links */
    }

    .d-flex {
        margin: 0; /* Ensure flex container has no additional margin TODO set this class to the proper subclass*/
    }


    /*
     ██████╗ ██╗      ██████╗ ██████╗  █████╗ ██╗
    ██╔════╝ ██║     ██╔═══██╗██╔══██╗██╔══██╗██║
    ██║  ███╗██║     ██║   ██║██████╔╝███████║██║
    ██║   ██║██║     ██║   ██║██╔══██╗██╔══██║██║
    ╚██████╔╝███████╗╚██████╔╝██████╔╝██║  ██║███████╗
     ╚═════╝ ╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝*/
     body, html {
         margin: 0;
         padding: 0;
         font-size: var(--base-font-size);
         background-color: var(--navbackground);
     }

    a {
        color: var(--navlink); /* Default link color */
        /*text-decoration: none;  Remove underline from links */
        transition: color 0.3s, text-decoration 0.3s; /* Smooth transition for color and text decoration changes */
    }

    /* Hover state for links */
    a:hover {
        color: var(--navlinkhover);
        text-decoration: underline; /* Underline on hover */
    }

    /* Active state for links (when clicked) */
    a:active {
        color: #003d7a; /* Color when the link is actively being clicked TODO set active var */
    }

    pre {
        white-space: pre-wrap; !important
    }


    /*
     ██████╗████████╗ ██████╗    ██████╗ ██╗   ██╗████████╗████████╗ ██████╗ ███╗   ██╗
    ██╔════╝╚══██╔══╝██╔════╝    ██╔══██╗██║   ██║╚══██╔══╝╚══██╔══╝██╔═══██╗████╗  ██║
    ██║        ██║   ██║         ██████╔╝██║   ██║   ██║      ██║   ██║   ██║██╔██╗ ██║
    ██║        ██║   ██║         ██╔══██╗██║   ██║   ██║      ██║   ██║   ██║██║╚██╗██║
    ╚██████╗   ██║   ╚██████╗    ██████╔╝╚██████╔╝   ██║      ██║   ╚██████╔╝██║ ╚████║
     ╚═════╝   ╚═╝    ╚═════╝    ╚═════╝  ╚═════╝    ╚═╝      ╚═╝    ╚═════╝ ╚═╝  ╚═══╝*/
    /* CSS to style the "Copy to Clipboard" button */
    .copy-to-clipboard-button {
        background-color: #262626;
        color: #9FAFAF;
        padding: 4px 8px;
        border: none;
        cursor: pointer;
        border-radius: 5px;
        margin-left: 10px;
        font-weight:bold;
    }

    .copy-to-clipboard-button:hover {
        background-color: #2F2F2F;
        color: #C3BF9F;
        transition: color 0.3s;
        font-weight:bold;
    }

    .copy-to-clipboard-button:active {
        background-color: #CCDC90;
        color: #000D18;
        font-weight:bold;
    }



    .scrollable-div {
        max-height: 200px; /* Adjust the height as needed */
    }


    /*
    ███╗   ██╗ █████╗ ██╗   ██╗    ███╗   ███╗███████╗███╗   ██╗██╗   ██╗
    ████╗  ██║██╔══██╗██║   ██║    ████╗ ████║██╔════╝████╗  ██║██║   ██║
    ██╔██╗ ██║███████║██║   ██║    ██╔████╔██║█████╗  ██╔██╗ ██║██║   ██║
    ██║╚██╗██║██╔══██║╚██╗ ██╔╝    ██║╚██╔╝██║██╔══╝  ██║╚██╗██║██║   ██║
    ██║ ╚████║██║  ██║ ╚████╔╝     ██║ ╚═╝ ██║███████╗██║ ╚████║╚██████╔╝
    ╚═╝  ╚═══╝╚═╝  ╚═╝  ╚═══╝      ╚═╝     ╚═╝╚══════╝╚═╝  ╚═══╝ ╚═════╝ */
    #DOX_navmenu_wrapper {
        background-color:var(--navbackground);
        margin: 0px;
        padding: 0px;
    }

    #DOX_navmenu {
        background-color: var(--navbackground);
        list-style-type: none;
        padding: 0;
        margin: 0;
    }

    #DOX_navmenu .nav-link {

        display: block; /* Ensure full width */
        padding: 10px 15px; /* Adjust padding */
        color: var(--navlink); /* Text color */
        transition: color 0.3s; /* Smooth color transition */
        white-space: normal; /* Allow text to wrap */
        overflow-wrap: break-word; /* Break long words */
        word-break: break-word; /* Break long words if necessary */

    }

    #DOX_navmenu .nav-link:hover {
        color: var(--navlinkhover); /* Hover color */
        text-decoration: none; /* Remove underline on hover */
    }

    #DOX_navmenu .disabledlink {
        color: #ccc; /* Disabled link color */
        cursor: not-allowed; /* Change cursor on disabled link */
        pointer-events: none; /* Disable click events on disabled link */
    }

    /* General font scaling for headings and other elements
    h1, h2, h3, h4, h5, h6,
    .breadcrumb, .breadcrumb-wrapper, .topbar,
    .sidebar, .list-group-item, .footer {
        font-size: calc(1vw + 1vh + 0.3vmin);
    }*/

    /* Specific adjustments for individual elements */
    #DOX_breadcrumb-wrapper {
        background-color: var(--navbackground);
    }

    .breadcrumb-item + .breadcrumb-item::before {
        content: '>'; /* Changes the separator to '>' */
        color: var(--navlinkhover); /* Optional: set the color */
    }

    .breadcrumb-item.active {
        color: var(--navlinkhover);
    }

    .breadcrumb a {
        color: var(--navlink);
    }

    .breadcrumb a:hover {
        color: var(--navlinkhover);
    }

    .breadcrumb {
        background: none;
        margin: 4px;
    }

    .breadcrumb-wrapper {
        background-color: var(--navbackground);
        padding: 5px 20px;
    }

    /*
    .sidebar-wrapper {
        height: calc(100vh - 126px); /* Adjusted height */
        overflow-y: auto; /* Add scrollbar if content exceeds height */
    }

    .sidebar {
        background-color: var(--navbackground);
        color: white;
        padding: 10px;
    }
*/
    .content-wrapper {
        padding: 0 20px;
    }

    .scrollable-list {
        overflow-y: auto;
        white-space: nowrap;
    }

    .list-group {
        display: flex;
        padding: 0;
    }

    .list-group-item {
        flex: 0 0 auto;
        margin-right: 10px; /* Adjust spacing between items */
    }

    .disabledlink {
        pointer-events: none;
        color: white;
    }



    .custom-section {
      margin: 20px 0;
    }

    #DOX_content_wrapper {
        background-color: var(--navbackground);
    }

    .section-title {
        background-color: var(--sectiontitlebg);
        color: var(--sectiontitle);
        padding: 10px; /* Adjust padding as needed */
        font-weight: bold; /* Make the title bold */
    }

    .section-content {
        color: var(--sectioncontent);
        background-color: var(--navbackground);
        padding: 10px; /* Adjust padding as needed */
        border: 1px solid #ccc; /* Add border for content area */
    }
]];
