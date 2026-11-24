<!-- Layout principal con sidebar fijo y header -->
<div class="__PREFIX__-layout" [class.sidebar-collapsed]="layoutService.state() === SidebarStatus.COLLAPSED" animate.enter="fade-in-out-enter" animate.leave="fade-in-out-leave">
  @if (layoutService.shouldRender()) {
    <__PREFIX__-sidebar></__PREFIX__-sidebar>
  }

  <div class="main-container">
    <__PREFIX__-header></__PREFIX__-header>

    <!-- El scroll GENERAL se hace aquí -->
    <main class="main-content">
      <div class="content-wrapper">
        <div #routeContainer class="route-container route-transition">
          <router-outlet (activate)="onRouteActivate()"></router-outlet>
        </div>
      </div>
    </main>
  </div>
</div>

@if (alertService.toastActive()) {
  <sa-toast />
}
