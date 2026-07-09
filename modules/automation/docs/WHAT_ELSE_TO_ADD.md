# What else is useful for Automation Studio frontend

Recommended additions:

1. Quick templates
   - "When task moves to Done → mark event done"
   - "When lead status changes → create task"
   - "When payment is on time → loyalty event"
   - "When email arrives → assign to lead"

2. Contextual launchers
   - TMS column menu
   - lead details page
   - advertisement details page
   - calendar event details
   - email thread panel
   - document details

3. Approval inbox
   - user sees pending automation approvals
   - approve/reject directly from top bar or dashboard

4. Run debugger
   - timeline of node execution
   - input/output per node
   - retry button
   - dead-letter view

5. Test mode
   - paste sample payload
   - highlight path taken on canvas
   - preview rendered templates like {{payload.email}}

6. Permission UX
   - company automation
   - private user automation
   - admins can edit company workflows
   - users can duplicate company workflow as personal

7. Versioning UX
   - draft vs active version
   - publish changes
   - rollback

8. Safety UX
   - warning before workflows affecting many records
   - rate limit badge
   - idempotency preview

9. Emma integration
   - "Create automation from prompt"
   - "Explain this workflow"
   - "Find why this automation failed"
   - "Suggest next action"

10. Module anchors
   - each contextual popup should provide sourceModule/sourceType/sourceId
   - useful for Emma UI anchors and guided flows
