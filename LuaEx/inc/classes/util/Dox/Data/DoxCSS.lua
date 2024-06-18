return [[
    :root {
            --banner-height: 10vh;
            --base-font-size: 16px; /* Define a base font size */
        }

        @media (min-width: 576px) {
            body {
                font-size: calc(var(--base-font-size) * 1.1);
            }
        }

        @media (min-width: 768px) {
            body {
                font-size: calc(var(--base-font-size) * 1.2);
            }
        }

        body, html {
            margin: 0;
            padding: 0;
            /* Add overflow:overflow: hidden;  hidden to prevent overflow issues */
            font-size: var(--base-font-size);
        }

        .scrollable-div {
            max-height: 200px; /* Adjust the height as needed */
        }

        #DOX_navmenu .nav-link {

            padding: 10px 15px; /* Adjust padding */
            color: #555; /* Text color */
            transition: color 0.3s; /* Smooth transition for color change */
        }

        #DOX_navmenu .nav-link:hover {
            color: #007bff; /* Hover color */
            text-decoration: none; /* Remove underline on hover */
        }

        #DOX_navmenu .disabledlink {
            color: #ccc; /* Disabled link color */
            cursor: not-allowed; /* Change cursor on disabled link */
            pointer-events: none; /* Disable click events on disabled link */
        }

        /* General font scaling for headings and other elements */
        h1, h2, h3, h4, h5, h6,
        .breadcrumb, .breadcrumb-wrapper, .topbar,
        .sidebar, .list-group-item, .footer {
            font-size: calc(1vw + 1vh + 0.3vmin);
        }

        /* Specific adjustments for individual elements */
        .breadcrumb {
            background: none;
            margin-bottom: 4px;
        }

        .breadcrumb-wrapper {
            background-color: #ffc107;
            padding: 5px 20px;
        }

        .sidebar-wrapper {
            height: calc(100vh - 126px); /* Adjusted height */
            overflow-y: auto; /* Add scrollbar if content exceeds height */
        }

        .sidebar {
            background-color: #343a40;
            color: white;
            padding: 10px;
        }

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

        #banner {
            background-image: url('${bannerURL}');
            background-repeat: repeat; /* Repeat the background image */
            background-size: auto; /* Use original image size */
            padding: 10px; /* Add padding for spacing */
            opacity: 0.9; /* Set opacity (0 = fully transparent, 1 = fully opaque) */
        }

        #title {
            font-family: 'Arial', sans-serif; /* Specify your preferred font-family */
            font-size: 2.5rem; /* Adjust font size as needed */
            font-weight: bold; /* Make the text bold */
            color: #3366cc; /* Choose a nice color for the text */
            text-align: center; /* Center-align the text */
            margin-bottom: 20px; /* Add some bottom margin for spacing */
        }

        #titlebg {
            background-color: rgba(200, 200, 200, 0.8); /* Background color with 50% transparency */
            border-radius: 10px; /* Rounded corners */
            padding: 20px; /* Add padding for spacing */
        }

        .custom-section {
          margin: 20px 0;
        }

        .section-title {
          background-color: #007bff; /* Blue color for the title bar */
          color: #fff; /* White text color */
          padding: 10px; /* Adjust padding as needed */
          font-weight: bold; /* Make the title bold */
        }

        .section-content {
          padding: 10px; /* Adjust padding as needed */
          border: 1px solid #ccc; /* Add border for content area */
        }
]];