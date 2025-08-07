# Documentation Directory - AI Assistant Context

## Documentation Structure

This directory contains comprehensive documentation for the whey protein price comparison platform. Each document serves specific audiences and purposes:

### Architecture & Technical Design
- **`architecture/architecture_doc.md`**: Complete system architecture, service interactions, data flow
- **`api/api_specification_complete.md`**: REST API endpoints, MCP tools, authentication flows
- **`deployment/deployment_guide.md`**: Production deployment, infrastructure, scaling strategies

### Development Guides  
- **`development/authentication_strategy.md`**: Multi-tier auth, OAuth2, GDPR compliance (175 pages)
- **`development/scraper_framework.md`**: User-driven scraping, anti-detection, configuration
- **`development/local_setup.md`**: Development environment, SQLite/PostgreSQL, VSCode config
- **`development/cicd_strategy.md`**: GitHub Actions, testing tiers, deployment pipeline
- **`development/security_checklist.md`**: MANDATORY secret leak prevention, GitGuardian integration

### Project Management
- **`project/project_plan.md`**: 8-sprint roadmap, measurable outcomes, dependencies, risks

## Key Documentation Themes

### Performance-First Approach
All documentation emphasizes:
- <14KB bundle size requirement (hard constraint)
- <500ms page load time target
- <50ms cached API responses
- 99.9% uptime goals

### User-Driven Architecture
- Scraping triggered by user searches (not scheduled crawling)
- Configurable rate limiting per retailer
- Price validation with confidence scoring
- GDPR-compliant user data handling

### Production-Ready Systems
- Comprehensive monitoring (Prometheus, Grafana, Jaeger)
- 4-tier testing strategy
- Database migration patterns
- Security hardening and audit logging

## AI Assistant Guidelines for Documentation

### MANDATORY Security Check (Before ANY commit)
1. **Secret Scan**: Run `docs/development/security_checklist.md` procedures
2. **Placeholder Format**: Use `<YOUR_*_HERE>` format for all credentials
3. **GitGuardian Safe**: Avoid patterns that trigger false positives
4. **Pre-commit Hooks**: Ensure security validation passes

### When Creating New Documentation
1. **Follow Existing Patterns**: Match style, structure, and detail level
2. **Include Measurable Outcomes**: Specific metrics and success criteria
3. **Reference Dependencies**: Link to related docs and systems
4. **Provide Examples**: Code snippets, configuration examples, CLI commands

### When Updating Existing Documentation
1. **Maintain Consistency**: Keep style and terminology consistent
2. **Update Cross-References**: Check for links to updated sections
3. **Verify Technical Accuracy**: Test code examples and commands
4. **Update Date Stamps**: Maintain version history where present

### Documentation Standards
- **Markdown Format**: Use GitHub-flavored markdown
- **Code Blocks**: Include language hints for syntax highlighting  
- **Tables**: Use for structured data (APIs, configurations, metrics)
- **Diagrams**: ASCII art or mermaid diagrams for architecture
- **Examples**: Working code examples, not pseudocode

## Content Guidelines by Document Type

### Architecture Documents
- Start with high-level overview and diagrams
- Detail service responsibilities and interfaces
- Include data flow and communication patterns
- Specify performance and scaling considerations

### API Documentation
- OpenAPI/Swagger compatibility preferred
- Include request/response examples
- Document error codes and handling
- Specify authentication and rate limiting

### Development Guides
- Step-by-step setup instructions
- Include troubleshooting sections
- Provide working code examples
- Reference configuration files and environment variables

## Critical Information to Include

### For Any Service Documentation
- Dependencies (internal and external)
- Configuration options and environment variables
- Health check endpoints and monitoring
- Error handling and logging patterns
- Performance characteristics and limitations

### For Database Documentation
- Schema diagrams and relationships
- Migration patterns and rollback procedures
- Indexing strategies and query optimization
- Backup and recovery procedures
- GDPR compliance and data retention

### For Frontend Documentation
- Bundle size impact analysis
- Performance optimization techniques
- Progressive enhancement patterns
- Accessibility considerations
- Browser compatibility requirements

## Cross-Document Relationships

### Core Dependencies
- **Project Plan** → drives all development documentation
- **Architecture** → referenced by API, deployment, and development docs  
- **Authentication Strategy** → referenced by API spec and development guides
- **Database Schemas** → referenced by API spec and architecture

### Update Propagation
When updating one document, consider impact on:
- **API changes** → update API spec, architecture, development guides
- **Database changes** → update migrations, API spec, architecture
- **Performance requirements** → update all technical documentation
- **Security changes** → update auth strategy, deployment guide, API spec

## Quality Checklist for Documentation Updates

### Technical Accuracy
- [ ] Code examples tested and working
- [ ] Configuration examples valid
- [ ] Command examples produce expected results
- [ ] Version numbers and dependencies current

### Completeness
- [ ] All necessary context provided
- [ ] Dependencies clearly specified
- [ ] Error scenarios documented
- [ ] Success criteria measurable

### Consistency
- [ ] Terminology matches other documents
- [ ] Style follows project standards
- [ ] Cross-references accurate and current
- [ ] Formatting consistent throughout

### Usability
- [ ] Clear structure with good navigation
- [ ] Examples relevant and practical
- [ ] Troubleshooting section included
- [ ] Contact/support information provided