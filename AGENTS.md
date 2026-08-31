# AGENTS.md
This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.
## Project Overview
This is a personal portfolio website built with Jekyll, showcasing engineering projects, artwork, and professional experiences. Every project page uses the Project Detail authoring contract. The site is hosted at https://imboning.com and features a responsive design with separate sections for projects, artwork, and experience timeline.
## Technology Stack
- **Static Site Generator**: Jekyll 4.4.1
- **Theme**: Minima with heavy customization
- **Styling**: SCSS/Sass with custom styles
- **JavaScript**: Dependency-free vanilla JavaScript modules
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
- **Main Layouts**: `project-detail.html` for every project detail page
- **Includes**: Modular components in `_includes/`:
  - `components/`: Shared navigation, footer, and responsive-image UI
  - `pages/`: Page-specific composition, including Project Detail blocks
### Page Structure
- `index.html`: Homepage with about, experience timeline, and work showcase
- `projects.html`: Project gallery page
- `artwork.html`: Artwork gallery page
- `resume.html`: Resume/CV page
### Asset Organization
- `assets/css/main.scss`: The public stylesheet entry point, composed from `_sass/foundation/`, `_sass/components/`, and `_sass/pages/`
- `assets/img/`: Images organized by content type (projects/, artwork/, experiences/)
- `assets/js/components/` and `assets/js/pages/`: Dependency-free behavior modules for shared and page-specific interactions
## Key Configuration
The `_config.yml` contains:
- Site metadata and branding
- Collection definitions with custom permalinks
- Sass compilation settings
- Jekyll plugin configuration
## Content Managemen
### Adding New Projects
1. Create `.md` file in `_projects/` directory
2. Use frontmatter with `layout: project-detail` and include title, subtitle, date, cover image, and tags.
3. Author a concise Intro before the first H1 when needed; H1 chapters generate the project navigation.
4. Use ordinary Markdown images for figures and documented typed directives for content Markdown cannot express; do not author structural HTML or Liquid includes.
5. Add project images to `assets/img/projects/[project-name]/`.
### Adding Artwork
1. Create `.md` file in `_artwork/` directory
2. Include image location and cover image paths
3. Add images to `assets/img/artwork/` and `assets/img/artwork/covers/`
### Managing Tags
- Tags are defined in `_tags/` directory
- Each tag includes ID, title, and gradient color scheme
- Used for project categorization and filtering
## Development Notes
- The modern site uses one compiled SCSS entry point and does not load Bootstrap, jQuery, or Popper.
- Vanilla JavaScript progressively enhances navigation and page interactions; Liquid renders content at build time.
- Responsive design optimized for mobile and desktop viewing
- Images are served locally from the assets directory
- Project Detail compiles Markdown, H1 navigation, figures, and typed directives at build time; see `docs/project-detail/README.md` before changing project content.
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
