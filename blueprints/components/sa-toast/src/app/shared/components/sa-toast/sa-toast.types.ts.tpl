export type ToastPosition = 'top-left' | 'top-center' | 'top-right' | 'bottom-left' | 'bottom-center' | 'bottom-right' | 'center';

export interface IAsToastAction {
  label: string;
  execute: () => void;
  secondary?: {
    label: string;
    execute: () => void;
  };
  variant?: 'primary' | 'danger';
}

export interface ToastItem {
  id: string;
  type: EAsToastType;
  title: string;
  message: string;
  action?: IAsToastAction;
  duration: number;
  persistent: boolean;
  position: ToastPosition;
  context?: 'view' | 'edit' | 'create';
}

export enum EAsToastType {
  Success = 'success',
  Info = 'info',
  Warning = 'warn',
  Error = 'error',
  Secondary = 'secondary',
  Contrast = 'contrast',
  Loading = 'loading',
}
