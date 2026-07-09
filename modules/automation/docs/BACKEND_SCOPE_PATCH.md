# Backend patch needed for company/user scopes

Add these fields to `AutomationWorkflow` if not present:

```python
scope_type = models.CharField(
    max_length=32,
    choices=[("user", "User"), ("company", "Company")],
    default="user",
    db_index=True,
)

company = models.ForeignKey(
    "user.Company",
    null=True,
    blank=True,
    on_delete=models.CASCADE,
    related_name="automation_workflows",
)

owner = models.ForeignKey(
    settings.AUTH_USER_MODEL,
    on_delete=models.CASCADE,
    related_name="automation_workflows",
)
```

Recommended permission rule:

- `scope_type=user`: only owner can edit/run
- `scope_type=company`: company admins can edit, members can view/use depending on role

Serializer fields expected by frontend:

```python
fields = [
    "id",
    "owner",
    "owner_id",
    "company",
    "company_id",
    "scope_type",
    "name",
    "description",
    "status",
    "trigger_keys",
    "graph_json",
    "created_at",
    "updated_at",
    "last_run_at",
]
```
