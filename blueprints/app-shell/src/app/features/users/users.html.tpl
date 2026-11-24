<section class="users flex flex-col gap-6">
  <header>
    <h1 class="text-body-1-bold text-(--app-text-color)">Users</h1>
    <p class="text-caption-1-regular text-(--app-text-subtle)">Sample data: replace this table with the users of your product.</p>
  </header>

  <div class="overflow-x-auto rounded-xl border border-(--app-border-color)">
    <table class="w-full min-w-[32rem] text-left">
      <thead class="text-caption-2-semibold uppercase tracking-[0.06em] text-(--app-text-subtle)">
        <tr class="border-b border-(--app-border-color)">
          <th class="px-4 py-3 font-semibold">Name</th>
          <th class="px-4 py-3 font-semibold">Role</th>
          <th class="px-4 py-3 font-semibold">Status</th>
        </tr>
      </thead>
      <tbody>
        @for (user of users; track user.email) {
          <tr class="border-b border-(--app-border-color) last:border-b-0">
            <td class="px-4 py-3">
              <div class="flex items-center gap-3">
                <sa-avatar [label]="initials(user.name)" [size]="36" background="var(--app-sidebar-user-avatar-bg)" color="var(--app-sidebar-user-avatar-text)" [alt]="user.name" />
                <div class="min-w-0">
                  <p class="text-caption-1-semibold text-(--app-text-color)">{{ user.name }}</p>
                  <p class="text-caption-2-regular text-(--app-text-subtle)">{{ user.email }}</p>
                </div>
              </div>
            </td>
            <td class="px-4 py-3 text-caption-1-medium text-(--app-text-color)">{{ user.role }}</td>
            <td class="px-4 py-3">
              <span class="text-caption-2-semibold" [class.text-(--app-status-online)]="user.active" [class.text-(--app-text-subtle)]="!user.active">{{ user.active ? 'Active' : 'Inactive' }}</span>
            </td>
          </tr>
        }
      </tbody>
    </table>
  </div>
</section>
