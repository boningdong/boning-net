# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a personal portfolio website built with Jekyll, showcasing engineering projects, artwork, and professional experiences. The site is hosted at https://imboning.com and features a responsive design with separate sections for projects, artwork, and experience timeline.

## Technology Stack

- **Static Site Generator**: Jekyll 4.4.1
- **Theme**: Minima with heavy customization
- **Styling**: SCSS/Sass with custom styles
- **JavaScript**: Vanilla JS with jQuery
- **Dependency Management**: Ruby Bundler
- **Deployment**: Configured for GitHub Pages (based on CNAME file)

## Development Commands

Since this is a Jekyll site, the primary development commands are:

```bash
# Install dependencies (requires Ruby)
bundle install

# Start development server with live reload
bundle exec jekyll serve

# Build static site for production
bundle exec jekyll build

# Clean build artifacts
bundle exec jekyll clean
```

**Note**: Ruby 3.3.5+ is required but may not be installed. Check Ruby version with `ruby -v` and install if needed.

## Site Architecture

### Content Structure
- **Collections**: The site uses Jekyll collections to organize content:
  - `_projects/`: Engineering and technical projects (12 projects)
  - `_artwork/`: Digital art and drawings (10 pieces)
  - `_experiences/`: Professional work history (6 positions)
  - `_tags/`: Tag definitions for categorizing projects

### Layout System
- **Main Layouts**: `project-post.html` for project details
- **Includes**: Modular components in `_includes/`:
  - `index/`: Homepage components (navbar, showcase, skills, timeline)
  - `showcase/`: Project/artwork gallery components
  - `header.html`: Shared page metadata

### Page Structure
- `index.html`: Homepage with about, experience timeline, and work showcase
- `projects.html`: Project gallery page
- `artwork.html`: Artwork gallery page
- `resume.html`: Resume/CV page

### Asset Organization
- `assets/css/`: Organized by page type (index/, showcase/)
- `assets/img/`: Images organized by content type (projects/, artwork/, experiences/)
- `assets/js/`: JavaScript organized by functionality

## Key Configuration

The `_config.yml` contains:
- Site metadata and branding
- Collection definitions with custom permalinks
- Sass compilation settings
- Jekyll plugin configuration

## Content Management

### Adding New Projects
1. Create `.md` file in `_projects/` directory
2. Use frontmatter with layout: `project-post`
3. Include required fields: title, subtitle, date, cover image, tags
4. Add project images to `assets/img/projects/[project-name]/`

### Adding Artwork
1. Create `.md` file in `_artwork/` directory
2. Include image location and cover image paths
3. Add images to `assets/img/artwork/` and `assets/img/artwork/covers/`

### Managing Tags
- Tags are defined in `_tags/` directory
- Each tag includes ID, title, and gradient color scheme
- Used for project categorization and filtering

## Development Notes

- The site uses extensive custom CSS with Bootstrap integration
- JavaScript handles interactive elements like project/artwork showcase toggles
- Responsive design optimized for mobile and desktop viewing
- Images are served locally from the assets directory

## Code Style Guidelines

When editing files in this repository, follow these formatting standards:

### Line Endings and Whitespace
- **Remove all trailing whitespace** from lines
- **Use Unix/macOS line endings** (LF `\n`) not Windows line endings (CRLF `\r\n`)
- Avoid leaving blank lines with only whitespace characters

### General Formatting
- Maintain consistent indentation within each file type
- Remove any stray `^M` characters (Windows carriage returns)
- Keep files clean and properly formatted